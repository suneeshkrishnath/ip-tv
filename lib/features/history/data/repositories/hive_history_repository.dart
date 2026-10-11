import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/history/domain/repositories/history_repository.dart';

const recentlyWatchedLimit = 20;

class HiveHistoryRepository implements HistoryRepository {
  const HiveHistoryRepository(this._box);

  static const _key = 'recent';

  final Box<String> _box;

  @override
  Future<Result<List<Channel>>> getRecent() async {
    try {
      return Success(_read());
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to read recently watched channels.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> record(Channel channel) async {
    try {
      final updated = [
        channel,
        ..._read().where((existing) => existing.id != channel.id),
      ].take(recentlyWatchedLimit).toList();
      await _box.put(
        _key,
        jsonEncode(updated.map((c) => c.toJson()).toList()),
      );
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to save watch history.', cause: error),
      );
    }
  }

  List<Channel> _read() {
    final encoded = _box.get(_key);
    if (encoded == null) return const [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('History must be a JSON list.');
    }
    return decoded
        .map((item) => Channel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
