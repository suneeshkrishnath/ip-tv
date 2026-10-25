import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

final selectedPlaylistSourceProvider =
    NotifierProvider<SelectedPlaylistSourceNotifier, PlaylistSource>(
      SelectedPlaylistSourceNotifier.new,
    );

class SelectedPlaylistSourceNotifier extends Notifier<PlaylistSource> {
  @override
  PlaylistSource build() => const PlaylistSource(
    id: 'malayalam',
    name: 'Malayalam',
    url: 'https://iptv-org.github.io/iptv/languages/mal.m3u',
  );

  void select(PlaylistSource source) => state = source;
}

final playlistSourcesProvider =
    AsyncNotifierProvider<PlaylistSourcesNotifier, List<PlaylistSource>>(
      PlaylistSourcesNotifier.new,
    );

/// Built-in sources followed by user-saved playlists.
class PlaylistSourcesNotifier extends AsyncNotifier<List<PlaylistSource>> {
  @override
  Future<List<PlaylistSource>> build() => _load();

  Future<List<PlaylistSource>> _load() async {
    final result = await ref.read(userPlaylistsRepositoryProvider).getAll();
    return switch (result) {
      Success<List<PlaylistSource>>(:final value) => [
        ...initialPlaylistSources,
        ...value,
      ],
      FailureResult<List<PlaylistSource>>(:final failure) => throw failure,
    };
  }

  /// Returns a failure message on error, or null on success.
  Future<AppFailure?> add({
    required String name,
    required String url,
    String? epgUrl,
  }) async {
    final result = await ref
        .read(userPlaylistsRepositoryProvider)
        .add(name: name, url: url, epgUrl: epgUrl);
    return _finish(result);
  }

  Future<AppFailure?> edit(
    PlaylistSource source, {
    required String name,
    required String url,
    String? epgUrl,
  }) async {
    final result = await ref
        .read(userPlaylistsRepositoryProvider)
        .edit(id: source.id, name: name, url: url, epgUrl: epgUrl);
    final failure = await _finish(result);
    if (result case Success<PlaylistSource>(:final value)) {
      if (ref.read(selectedPlaylistSourceProvider).id == source.id) {
        ref.read(selectedPlaylistSourceProvider.notifier).select(value);
        ref.invalidate(currentPlaylistProvider);
      }
    }
    return failure;
  }

  Future<AppFailure?> delete(PlaylistSource source) async {
    final result = await ref
        .read(userPlaylistsRepositoryProvider)
        .delete(source.id);
    final failure = await _finish(result);
    if (result is Success<void> &&
        ref.read(selectedPlaylistSourceProvider).id == source.id) {
      ref
          .read(selectedPlaylistSourceProvider.notifier)
          .select(initialPlaylistSources.first);
      ref.invalidate(currentPlaylistProvider);
    }
    return failure;
  }

  Future<AppFailure?> _finish(Result<Object?> result) async {
    if (result is FailureResult) return result.failure;
    state = AsyncData(await _load());
    return null;
  }
}

final currentPlaylistProvider =
    AsyncNotifierProvider<CurrentPlaylistNotifier, Playlist?>(
      CurrentPlaylistNotifier.new,
    );

class CurrentPlaylistNotifier extends AsyncNotifier<Playlist?> {
  /// Starts from the cached playlist so the app works offline.
  @override
  Future<Playlist?> build() =>
      _cached(ref.read(selectedPlaylistSourceProvider));

  Future<Playlist?> _cached(PlaylistSource source) async {
    final result = await ref
        .read(playlistRepositoryProvider)
        .getCachedPlaylist(source.id);
    return result is Success<Playlist?> ? result.value : null;
  }

  Future<void> showCached(PlaylistSource source) async {
    final cached = await _cached(source);
    ref.read(playlistOfflineProvider.notifier).set(false);
    state = AsyncData(cached);
  }

  void clearVisiblePlaylist() => state = const AsyncData(null);

  /// Falls back to the cached playlist when the download fails.
  Future<void> loadSource(PlaylistSource source) async {
    state = const AsyncLoading();
    final result = await ref
        .read(playlistRepositoryProvider)
        .loadPlaylist(source);
    switch (result) {
      case Success<Playlist>(:final value):
        ref.read(playlistOfflineProvider.notifier).set(false);
        state = AsyncData(value);
      case FailureResult<Playlist>(:final failure):
        final cached = await _cached(source);
        if (cached != null) {
          ref.read(playlistOfflineProvider.notifier).set(true);
          state = AsyncData(cached);
        } else {
          state = AsyncError(failure, StackTrace.current);
        }
    }
  }
}

/// True when the shown playlist is saved data because refreshing failed.
final playlistOfflineProvider = NotifierProvider<PlaylistOfflineNotifier, bool>(
  PlaylistOfflineNotifier.new,
);

class PlaylistOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final channelSearchQueryProvider =
    NotifierProvider<ChannelSearchQueryNotifier, String>(
      ChannelSearchQueryNotifier.new,
    );

class ChannelSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final selectedChannelCategoryProvider =
    NotifierProvider<SelectedChannelCategoryNotifier, String?>(
      SelectedChannelCategoryNotifier.new,
    );

class SelectedChannelCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

List<Channel> filterChannels(
  List<Channel> channels, {
  required String query,
  String? category,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return channels
      .where((channel) {
        final matchesCategory =
            category == null || channel.category == category;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            channel.name.toLowerCase().contains(normalizedQuery) ||
            channel.category.toLowerCase().contains(normalizedQuery);
        return matchesCategory && matchesQuery;
      })
      .toList(growable: false);
}
