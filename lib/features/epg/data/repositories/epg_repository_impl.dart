import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/logging/app_logger.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_local_data_source.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_remote_data_source.dart';
import 'package:ip_tv/features/epg/data/parsers/xmltv_parser.dart';
import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';
import 'package:ip_tv/features/epg/domain/repositories/epg_repository.dart';

typedef EpgParse = Future<EpgGuide> Function(
  String xml,
  Set<String>? channelIds,
  DateTime fetchedAt,
);

typedef _ParseArgs = ({String xml, Set<String>? ids, DateTime at});

EpgGuide _parseSync(_ParseArgs args) =>
    XmltvParser().parse(args.xml, channelIds: args.ids, fetchedAt: args.at);

Future<EpgGuide> parseInIsolate(
  String xml,
  Set<String>? channelIds,
  DateTime fetchedAt,
) {
  return compute(_parseSync, (xml: xml, ids: channelIds, at: fetchedAt));
}

class EpgRepositoryImpl implements EpgRepository {
  EpgRepositoryImpl({
    required EpgRemoteDataSource remoteDataSource,
    EpgLocalDataSource? localDataSource,
    EpgParse? parse,
    DateTime Function()? clock,
    this.cacheMaxAge = const Duration(hours: 6),
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _parse = parse ?? parseInIsolate,
       _clock = clock ?? DateTime.now;

  final EpgRemoteDataSource _remote;
  final EpgLocalDataSource? _local;
  final EpgParse _parse;
  final DateTime Function() _clock;
  final Duration cacheMaxAge;

  /// Returns a fresh cached guide, otherwise downloads; a stale cached guide
  /// is used when the download fails.
  @override
  Future<Result<EpgGuide>> loadGuide(
    String epgUrl, {
    Set<String>? channelIds,
  }) async {
    final key = _cacheKey(epgUrl, channelIds);
    final cached = await _readCache(key);
    final now = _clock().toUtc();
    final fetchedAt = cached?.fetchedAt;
    if (cached != null &&
        fetchedAt != null &&
        now.difference(fetchedAt) < cacheMaxAge) {
      return Success(cached);
    }

    final downloaded = await _download(epgUrl, channelIds, now);
    switch (downloaded) {
      case Success<EpgGuide>(:final value):
        await _writeCache(key, value);
        return downloaded;
      case FailureResult<EpgGuide>():
        return cached == null ? downloaded : Success(cached);
    }
  }

  Future<Result<EpgGuide>> _download(
    String epgUrl,
    Set<String>? channelIds,
    DateTime now,
  ) async {
    try {
      final xml = await _remote.fetch(epgUrl);
      return Success(await _parse(xml, channelIds, now));
    } on DioException catch (error, stackTrace) {
      appLogger.e('Guide download failed', error: error, stackTrace: stackTrace);
      return FailureResult(EpgFailure.fromDio(error));
    } on FormatException catch (error, stackTrace) {
      appLogger.e('Guide parsing failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        EpgFailure(
          'The TV guide is not valid XMLTV. ${error.message}',
          cause: error,
          code: 'EPG-PARSE',
        ),
      );
    } catch (error, stackTrace) {
      appLogger.e('Unexpected guide failure', error: error, stackTrace: stackTrace);
      return FailureResult(
        EpgFailure('Unable to load the TV guide.', cause: error),
      );
    }
  }

  Future<EpgGuide?> _readCache(String key) async {
    try {
      return await _local?.get(key);
    } catch (error, stackTrace) {
      appLogger.w('Guide cache read failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _writeCache(String key, EpgGuide guide) async {
    try {
      await _local?.put(key, guide);
    } catch (error, stackTrace) {
      appLogger.w('Guide cache write failed', error: error, stackTrace: stackTrace);
    }
  }

  /// Stable key (FNV-1a) so a different channel set never reuses a guide.
  String _cacheKey(String url, Set<String>? channelIds) {
    final ids = channelIds?.map(EpgGuide.normalizeId).toList()?..sort();
    var hash = 0x811c9dc5;
    for (final unit in '$url|${ids?.join(',')}'.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
