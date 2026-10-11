import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/core/storage/hive_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/history/data/repositories/hive_history_repository.dart';
import 'package:ip_tv/features/history/domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HiveHistoryRepository(ref.watch(historyBoxProvider));
});

final recentlyWatchedProvider =
    AsyncNotifierProvider<RecentlyWatchedNotifier, List<Channel>>(
  RecentlyWatchedNotifier.new,
);

class RecentlyWatchedNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() => _load();

  Future<List<Channel>> _load() async {
    final result = await ref.read(historyRepositoryProvider).getRecent();
    return switch (result) {
      Success<List<Channel>>(:final value) => value,
      FailureResult<List<Channel>>(:final failure) => throw failure,
    };
  }

  Future<void> record(Channel channel) async {
    final result = await ref.read(historyRepositoryProvider).record(channel);
    switch (result) {
      case Success<void>():
        state = AsyncData(await _load());
      case FailureResult<void>(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }
}
