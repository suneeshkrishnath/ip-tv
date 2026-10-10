import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';

void main() {
  testWidgets('selecting a channel passes it to the player route', (tester) async {
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
    await tester.tap(find.text(channel.name));
    await tester.pumpAndSettle();

    expect(find.text(channel.streamUrl), findsOneWidget);
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