import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

final selectedPlaylistSourceProvider = NotifierProvider<
  SelectedPlaylistSourceNotifier,
  PlaylistSource
>(SelectedPlaylistSourceNotifier.new);

class SelectedPlaylistSourceNotifier extends Notifier<PlaylistSource> {
  @override
  PlaylistSource build() => const PlaylistSource(
    id: 'malayalam',
    name: 'Malayalam',
    url: 'https://iptv-org.github.io/iptv/languages/mal.m3u',
  );

  void select(PlaylistSource source) => state = source;
}

final currentPlaylistProvider = AsyncNotifierProvider<
  CurrentPlaylistNotifier,
  Playlist?
>(CurrentPlaylistNotifier.new);

class CurrentPlaylistNotifier extends AsyncNotifier<Playlist?> {
  @override
  Future<Playlist?> build() async => null;

  Future<void> loadSource(PlaylistSource source) async {
    state = const AsyncLoading();
    final result = await ref.read(playlistRepositoryProvider).loadPlaylist(source);
    state = switch (result) {
      Success<Playlist>(:final value) => AsyncData(value),
      FailureResult<Playlist>(:final failure) =>
        AsyncError(failure, StackTrace.current),
    };
  }
}

final channelSearchQueryProvider = NotifierProvider<
  ChannelSearchQueryNotifier,
  String
>(ChannelSearchQueryNotifier.new);

class ChannelSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final selectedChannelCategoryProvider = NotifierProvider<
  SelectedChannelCategoryNotifier,
  String?
>(SelectedChannelCategoryNotifier.new);

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
  return channels.where((channel) {
    final matchesCategory = category == null || channel.category == category;
    final matchesQuery = normalizedQuery.isEmpty ||
        channel.name.toLowerCase().contains(normalizedQuery) ||
        channel.category.toLowerCase().contains(normalizedQuery);
    return matchesCategory && matchesQuery;
  }).toList(growable: false);
}