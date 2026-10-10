import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/app/router.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/application/favorite_providers.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:ip_tv/features/player/presentation/player_providers.dart';
import 'package:ip_tv/features/player/presentation/player_session.dart';

import 'support/fake_favorite_repository.dart';

void main() {
  testWidgets('selecting a channel passes it to the player route', (tester) async {
    appRouter.go('/');
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
        favoriteRepositoryProvider.overrideWithValue(FakeFavoriteRepository()),
        playerSessionFactoryProvider.overrideWithValue(
          _FakePlayerSessionFactory(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentPlaylistProvider.future);
    await container.read(currentPlaylistProvider.notifier).loadSource(source);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IptvApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play ${channel.name}'));
    await tester.pumpAndSettle();

    expect(find.text(channel.name), findsNWidgets(2));
    expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);
  });
  
  testWidgets('a saved favorite opens in the in-app player', (tester) async {
    appRouter.go('/');
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
        favoriteRepositoryProvider.overrideWithValue(FakeFavoriteRepository()),
        playerSessionFactoryProvider.overrideWithValue(
          _FakePlayerSessionFactory(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentPlaylistProvider.future);
    await container.read(favoriteChannelsProvider.future);
    await container.read(currentPlaylistProvider.notifier).loadSource(source);
  
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IptvApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
  
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Play ${channel.name}'));
    await tester.pumpAndSettle();
  
    expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);
    expect(find.text(channel.streamUrl), findsNothing);
  });
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

class _FakePlayerSessionFactory implements PlayerSessionFactory {
  @override
  PlayerSession create() => _FakePlayerSession();
}

class _FakePlayerSession implements PlayerSession {
  @override
  Stream<bool> get playing => Stream.value(false);

  @override
  Stream<bool> get buffering => Stream.value(false);

  @override
  Stream<double> get volume => Stream.value(100);

  @override
  Stream<String> get errors => const Stream.empty();

  @override
  Widget videoView() => const ColoredBox(
        key: ValueKey('fake-video'),
        color: Colors.black,
      );

  @override
  Future<void> open(String streamUrl) async {}

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async {}
}