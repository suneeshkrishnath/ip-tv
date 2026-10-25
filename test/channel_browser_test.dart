import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:ip_tv/features/history/application/history_providers.dart';
import 'package:ip_tv/features/history/domain/repositories/history_repository.dart';
import 'package:ip_tv/features/player/application/player_controller.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:ip_tv/features/playlists/domain/repositories/user_playlists_repository.dart';
import 'package:ip_tv/features/settings/application/settings_providers.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';

import 'disclaimer_test.dart' show FakeDisclaimer;
import 'player_controller_test.dart' show FakePlayerEngine;

void main() {
  testWidgets('selecting a channel passes it to the player route', (
    tester,
  ) async {
    final source = initialPlaylistSources.first;
    const channel = Channel(
      id: 'news',
      name: 'Example News',
      streamUrl: 'https://example.test/live.m3u8',
      category: 'News',
    );
    final playlist = Playlist(
      id: source.id,
      name: source.name,
      sourceUrl: source.url,
      channels: const [channel],
    );
    final container = ProviderContainer(
      overrides: [
        playlistRepositoryProvider.overrideWithValue(
          _FakePlaylistRepository(playlist),
        ),
        favoritesRepositoryProvider.overrideWithValue(_FakeFavorites()),
        historyRepositoryProvider.overrideWithValue(_FakeHistory()),
        disclaimerAcceptedProvider.overrideWith(
          () => FakeDisclaimer(initial: true),
        ),
        playerEngineFactoryProvider.overrideWithValue(FakePlayerEngine.new),
        userPlaylistsRepositoryProvider.overrideWithValue(
          _FakeUserPlaylistsRepository(),
        ),
        themeModeProvider.overrideWith(_TestThemeModeNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentPlaylistProvider.future);
    await container.read(currentPlaylistProvider.notifier).loadSource(source);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const IptvApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<PlaylistSource>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(source.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(channel.name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(channel.name), findsWidgets);
    expect(find.byTooltip('Pause'), findsNothing);
    expect(find.byTooltip('Play'), findsOneWidget);
  });
}

class _FakeHistory implements HistoryRepository {
  @override
  Future<Result<List<Channel>>> getRecent() async => const Success([]);

  @override
  Future<Result<void>> record(Channel channel) async => const Success(null);
}

class _FakeFavorites implements FavoritesRepository {
  @override
  Future<Result<List<Channel>>> getFavorites() async => const Success([]);

  @override
  Future<Result<void>> addFavorite(Channel channel) async =>
      const Success(null);

  @override
  Future<Result<void>> removeFavorite(String channelId) async =>
      const Success(null);
}

class _FakePlaylistRepository implements PlaylistRepository {
  const _FakePlaylistRepository(this.playlist);

  final Playlist playlist;

  @override
  Future<Result<Playlist>> loadPlaylist(PlaylistSource source) async =>
      Success(playlist);

  @override
  Future<Result<Playlist?>> getCachedPlaylist(String playlistId) async =>
      const Success(null);
}

class _FakeUserPlaylistsRepository implements UserPlaylistsRepository {
  @override
  Future<Result<List<PlaylistSource>>> getAll() async => const Success([]);

  @override
  Future<Result<PlaylistSource>> add({
    required String name,
    required String url,
    String? epgUrl,
  }) async => throw UnimplementedError();

  @override
  Future<Result<PlaylistSource>> edit({
    required String id,
    required String name,
    required String url,
    String? epgUrl,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> delete(String id) async => throw UnimplementedError();
}

class _TestThemeModeNotifier extends ThemeModeNotifier {
  @override
  AppThemeMode build() => AppThemeMode.dark;
}
