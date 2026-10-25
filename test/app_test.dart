import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';
import 'package:ip_tv/features/settings/application/settings_providers.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:ip_tv/features/playlists/domain/repositories/user_playlists_repository.dart';

import 'disclaimer_test.dart' show FakeDisclaimer;

void main() {
  testWidgets('app routes to the IPTV home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disclaimerAcceptedProvider.overrideWith(
            () => FakeDisclaimer(initial: true),
          ),
          playlistRepositoryProvider.overrideWithValue(_EmptyRepository()),
          userPlaylistsRepositoryProvider.overrideWithValue(
            _EmptyUserPlaylistsRepository(),
          ),
          themeModeProvider.overrideWith(_TestThemeModeNotifier.new),
        ],
        child: const IptvApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('Favorites'), findsWidgets);
    expect(find.text('Browse by category'), findsOneWidget);
    expect(find.text('Recently watched'), findsOneWidget);
  });
}

class _EmptyRepository implements PlaylistRepository {
  @override
  Future<Result<Playlist>> loadPlaylist(PlaylistSource source) async =>
      const FailureResult(NetworkFailure('offline'));

  @override
  Future<Result<Playlist?>> getCachedPlaylist(String playlistId) async =>
      const Success(null);
}

class _EmptyUserPlaylistsRepository implements UserPlaylistsRepository {
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
