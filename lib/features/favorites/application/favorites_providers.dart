import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/core/storage/hive_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/data/repositories/hive_favorites_repository.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return HiveFavoritesRepository(ref.watch(favoritesBoxProvider));
});

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Channel>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() => _load();

  Future<List<Channel>> _load() async {
    final result = await ref.read(favoritesRepositoryProvider).getFavorites();
    return switch (result) {
      Success<List<Channel>>(:final value) => value,
      FailureResult<List<Channel>>(:final failure) => throw failure,
    };
  }

  Future<void> toggle(Channel channel) async {
    final repository = ref.read(favoritesRepositoryProvider);
    final isFavorite =
        state.value?.any((favorite) => favorite.id == channel.id) ?? false;
    final result = isFavorite
        ? await repository.removeFavorite(channel.id)
        : await repository.addFavorite(channel);
    switch (result) {
      case Success<void>():
        state = AsyncData(await _load());
      case FailureResult<void>(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }
}

final isFavoriteProvider = Provider.family<bool, String>((ref, channelId) {
  final favorites = ref.watch(favoritesProvider).value ?? const <Channel>[];
  return favorites.any((favorite) => favorite.id == channelId);
});
