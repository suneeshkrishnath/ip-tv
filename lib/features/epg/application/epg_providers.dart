import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/network/dio_provider.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/core/storage/hive_providers.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_local_data_source.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_remote_data_source.dart';
import 'package:ip_tv/features/epg/data/repositories/epg_repository_impl.dart';
import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';
import 'package:ip_tv/features/epg/domain/repositories/epg_repository.dart';

final epgRepositoryProvider = Provider<EpgRepository>((ref) {
  return EpgRepositoryImpl(
    remoteDataSource: DioEpgRemoteDataSource(ref.watch(dioProvider)),
    localDataSource: HiveEpgLocalDataSource(ref.watch(epgBoxProvider)),
  );
});

/// Guide for the loaded playlist, or null when its source has no guide URL.
final epgGuideProvider = FutureProvider<EpgGuide?>((ref) async {
  final epgUrl = ref.watch(selectedPlaylistSourceProvider).epgUrl;
  final playlist = ref.watch(currentPlaylistProvider).value;
  if (epgUrl == null || playlist == null) return null;

  final ids = {
    for (final channel in playlist.channels)
      if (channel.epgId != null) channel.epgId!,
  };
  final result = await ref
      .read(epgRepositoryProvider)
      .loadGuide(epgUrl, channelIds: ids);
  return switch (result) {
    Success<EpgGuide>(:final value) => value,
    FailureResult<EpgGuide>(:final failure) => throw failure,
  };
});
