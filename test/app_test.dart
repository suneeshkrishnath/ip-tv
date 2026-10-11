import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';

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
        ],
        child: const IptvApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('No playlist loaded'), findsOneWidget);
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