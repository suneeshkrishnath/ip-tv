import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_remote_data_source.dart';
import 'package:ip_tv/features/playlists/data/parsers/m3u_parser.dart';
import 'package:ip_tv/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:ip_tv/features/playlists/data/validators/playlist_validator.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

void main() {
  const source = PlaylistSource(
    id: 'test',
    name: 'Test playlist',
    url: 'https://example.test/list.m3u',
  );
  const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="channel.one" group-title="News",Channel One
https://example.test/live.m3u8
''';

  group('PlaylistRepositoryImpl', () {
    test('downloads, validates, and caches a playlist', () async {
      final local = _FakeLocalDataSource();
      final repository = _createRepository(
        remote: _FakeRemoteDataSource(content: content),
        local: local,
      );

      final result = await repository.loadPlaylist(source);

      expect(result, isA<Success<Playlist>>());
      final playlist = (result as Success<Playlist>).value;
      expect(playlist.channels.single.streamUrl, 'https://example.test/live.m3u8');
      expect(playlist.lastUpdated, DateTime.utc(2026, 10, 10));
      expect(local.playlists[source.id], playlist);
    });

    test('maps download errors to network failures', () async {
      final repository = _createRepository(
        remote: _FakeRemoteDataSource(
          error: DioException(requestOptions: RequestOptions(path: source.url)),
        ),
        local: _FakeLocalDataSource(),
      );

      final result = await repository.loadPlaylist(source);

      expect(result, isA<FailureResult<Playlist>>());
      expect((result as FailureResult<Playlist>).failure, isA<NetworkFailure>());
    });

    test('maps invalid playlist text to parsing failures', () async {
      final repository = _createRepository(
        remote: _FakeRemoteDataSource(content: 'not an M3U playlist'),
        local: _FakeLocalDataSource(),
      );

      final result = await repository.loadPlaylist(source);

      expect(
        (result as FailureResult<Playlist>).failure,
        isA<PlaylistParsingFailure>(),
      );
    });

    test('reports cache write errors without losing their cause', () async {
      final repository = _createRepository(
        remote: _FakeRemoteDataSource(content: content),
        local: _FakeLocalDataSource(cacheError: StateError('disk full')),
      );

      final result = await repository.loadPlaylist(source);

      final failure = (result as FailureResult<Playlist>).failure;
      expect(failure, isA<CacheFailure>());
      expect(failure.cause, isA<StateError>());
    });

    test('loads cached playlists and maps cache read errors', () async {
      final playlist = Playlist(
        id: source.id,
        name: source.name,
        sourceUrl: source.url,
      );
      final local = _FakeLocalDataSource()..playlists[source.id] = playlist;
      final repository = _createRepository(
        remote: _FakeRemoteDataSource(content: content),
        local: local,
      );

      final cachedResult = await repository.getCachedPlaylist(source.id);
      expect(cachedResult, isA<Success<Playlist?>>());
      expect((cachedResult as Success<Playlist?>).value, playlist);

      local.readError = StateError('corrupt cache');
      final result = await repository.getCachedPlaylist(source.id);
      expect((result as FailureResult<Playlist?>).failure, isA<CacheFailure>());
    });
  });
}

PlaylistRepositoryImpl _createRepository({
  required PlaylistRemoteDataSource remote,
  required _FakeLocalDataSource local,
}) {
  return PlaylistRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    parser: M3uParser(),
    validator: PlaylistValidator(),
    clock: () => DateTime.utc(2026, 10, 10),
  );
}

class _FakeRemoteDataSource implements PlaylistRemoteDataSource {
  const _FakeRemoteDataSource({this.content, this.error});

  final String? content;
  final Object? error;

  @override
  Future<String> fetch(String sourceUrl) async {
    if (error case final Object error) throw error;
    return content!;
  }
}

class _FakeLocalDataSource implements PlaylistLocalDataSource {
  _FakeLocalDataSource({this.cacheError});

  final Map<String, Playlist> playlists = {};
  final Object? cacheError;
  Object? readError;

  @override
  Future<void> cache(Playlist playlist) async {
    if (cacheError case final Object error) throw error;
    playlists[playlist.id] = playlist;
  }

  @override
  Future<Playlist?> get(String playlistId) async {
    if (readError case final Object error) throw error;
    return playlists[playlistId];
  }

  @override
  Future<void> remove(String playlistId) async {
    playlists.remove(playlistId);
  }
}