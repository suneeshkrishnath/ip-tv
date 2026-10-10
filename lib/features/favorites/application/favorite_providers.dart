import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/core/storage/favorite_box_provider.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/data/datasources/favorite_local_data_source.dart';
import 'package:ip_tv/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorite_repository.dart';

final favoriteLocalDataSourceProvider = Provider<FavoriteLocalDataSource>(
  (ref) => HiveFavoriteLocalDataSource(ref.watch(favoriteBoxProvider)),
);

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepositoryImpl(ref.watch(favoriteLocalDataSourceProvider)),
);

final favoriteChannelsProvider = AsyncNotifierProvider<
  FavoriteChannelsNotifier,
  List<Channel>
>(FavoriteChannelsNotifier.new);

class FavoriteChannelsNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() async {
    final result = await ref.read(favoriteRepositoryProvider).getFavorites();
    return switch (result) {
      Success<List<Channel>>(:final value) => value,
      FailureResult<List<Channel>>(:final failure) => throw failure,
    };
  }

  Future<void> toggle(Channel channel) async {
    final current = state.value ?? const <Channel>[];
    final isFavorite = current.any((item) => item.id == channel.id);
    final result = isFavorite
        ? await ref.read(favoriteRepositoryProvider).removeFavorite(channel.id)
        : await ref.read(favoriteRepositoryProvider).addFavorite(channel);

    switch (result) {
      case Success<void>():
        state = AsyncData(
          isFavorite
              ? current.where((item) => item.id != channel.id).toList()
              : [...current, channel],
        );
      case FailureResult<void>(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }

  Future<void> remove(Channel channel) async {
    final current = state.value ?? const <Channel>[];
    final result = await ref.read(favoriteRepositoryProvider).removeFavorite(
          channel.id,
        );
    switch (result) {
      case Success<void>():
        state = AsyncData(
          current.where((item) => item.id != channel.id).toList(),
        );
      case FailureResult<void>(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }
}