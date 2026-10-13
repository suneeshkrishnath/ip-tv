import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_local_data_source.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_remote_data_source.dart';
import 'package:ip_tv/features/epg/data/parsers/xmltv_parser.dart';
import 'package:ip_tv/features/epg/data/repositories/epg_repository_impl.dart';
import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';

const _source = PlaylistSource(
  id: 'malayalam',
  name: 'Malayalam',
  url: 'https://example.test/list.m3u',
);
const _cachedPlaylist = Playlist(
  id: 'malayalam',
  name: 'Malayalam',
  sourceUrl: 'https://example.test/list.m3u',
  channels: [
    Channel(id: 'a', name: 'Cached Channel', streamUrl: 'https://x.test/a'),
  ],
);

class _FakePlaylistRepository implements PlaylistRepository {
  _FakePlaylistRepository({this.cached, this.loadFailure});

  final Playlist? cached;
  final AppFailure? loadFailure;

  @override
  Future<Result<Playlist>> loadPlaylist(PlaylistSource source) async {
    final failure = loadFailure;
    if (failure != null) return FailureResult(failure);
    return Success(_cachedPlaylist);
  }

  @override
  Future<Result<Playlist?>> getCachedPlaylist(String playlistId) async =>
      Success(cached);
}

ProviderContainer _container(_FakePlaylistRepository repository) {
  final container = ProviderContainer(
    overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

class _MemoryEpgCache implements EpgLocalDataSource {
  final entries = <String, EpgGuide>{};
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<EpgGuide?> get(String key) async {
    if (failReads) throw StateError('corrupt');
    return entries[key];
  }

  @override
  Future<void> put(String key, EpgGuide guide) async {
    if (failWrites) throw StateError('disk full');
    entries[key] = guide;
  }
}

class _CountingRemote implements EpgRemoteDataSource {
  int calls = 0;
  bool fail = false;

  @override
  Future<String> fetch(String epgUrl) async {
    calls++;
    if (fail) throw DioException(requestOptions: RequestOptions());
    return '''
<tv><programme start="20261011100000 +0000" stop="20261011110000 +0000" channel="a">
<title>Show</title></programme></tv>''';
  }
}

void main() {
  group('offline playlists', () {
    test('starts from the cached playlist', () async {
      final container = _container(_FakePlaylistRepository(cached: _cachedPlaylist));

      final playlist = await container.read(currentPlaylistProvider.future);

      expect(playlist, _cachedPlaylist);
    });

    test('starts empty when nothing is cached', () async {
      final container = _container(_FakePlaylistRepository());

      expect(await container.read(currentPlaylistProvider.future), isNull);
    });

    test('falls back to the cache when refreshing fails', () async {
      final container = _container(
        _FakePlaylistRepository(
          cached: _cachedPlaylist,
          loadFailure: const NetworkFailure('offline'),
        ),
      );
      await container.read(currentPlaylistProvider.future);

      await container.read(currentPlaylistProvider.notifier).loadSource(_source);

      expect(container.read(currentPlaylistProvider).value, _cachedPlaylist);
      expect(container.read(playlistOfflineProvider), isTrue);
    });

    test('reports the error when refreshing fails with no cache', () async {
      final container = _container(
        _FakePlaylistRepository(loadFailure: const NetworkFailure('offline')),
      );
      await container.read(currentPlaylistProvider.future);

      await container.read(currentPlaylistProvider.notifier).loadSource(_source);

      expect(container.read(currentPlaylistProvider).hasError, isTrue);
      expect(container.read(playlistOfflineProvider), isFalse);
    });

    test('a successful refresh clears the offline flag', () async {
      final container = _container(_FakePlaylistRepository(cached: _cachedPlaylist));
      container.read(playlistOfflineProvider.notifier).set(true);
      await container.read(currentPlaylistProvider.future);

      await container.read(currentPlaylistProvider.notifier).loadSource(_source);

      expect(container.read(playlistOfflineProvider), isFalse);
    });

    test('showCached swaps in the cached playlist for a source', () async {
      final container = _container(_FakePlaylistRepository(cached: _cachedPlaylist));
      await container.read(currentPlaylistProvider.future);

      await container.read(currentPlaylistProvider.notifier).showCached(_source);

      expect(container.read(currentPlaylistProvider).value, _cachedPlaylist);
    });
  });

  group('guide cache', () {
    final now = DateTime.utc(2026, 10, 11, 10, 30);
    late _MemoryEpgCache cache;
    late _CountingRemote remote;
    var current = DateTime.utc(2026, 10, 11, 10, 30);

    EpgRepositoryImpl repository() => EpgRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: cache,
      parse: (xml, ids, at) async =>
          XmltvParser().parse(xml, channelIds: ids, fetchedAt: at),
      clock: () => current,
    );

    setUp(() {
      cache = _MemoryEpgCache();
      remote = _CountingRemote();
      current = now;
    });

    test('reuses a fresh cached guide without downloading', () async {
      final repo = repository();
      await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});
      current = now.add(const Duration(hours: 1));
      final result =
          await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});

      expect(remote.calls, 1);
      expect((result as Success<EpgGuide>).value.currentProgram('a', now),
          isNotNull);
    });

    test('redownloads once the cache is older than the max age', () async {
      final repo = repository();
      await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});
      current = now.add(const Duration(hours: 7));
      await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});

      expect(remote.calls, 2);
    });

    test('uses a stale cached guide when the download fails', () async {
      final repo = repository();
      await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});
      current = now.add(const Duration(hours: 7));
      remote.fail = true;

      final result =
          await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});

      expect(result, isA<Success<EpgGuide>>());
    });

    test('does not share cache entries between channel sets', () async {
      final repo = repository();
      await repo.loadGuide('https://example.test/g.xml', channelIds: {'a'});
      await repo.loadGuide('https://example.test/g.xml', channelIds: {'a', 'b'});

      expect(remote.calls, 2);
      expect(cache.entries, hasLength(2));
    });

    test('ignores cache read and write failures', () async {
      cache
        ..failReads = true
        ..failWrites = true;

      final result = await repository()
          .loadGuide('https://example.test/g.xml', channelIds: {'a'});

      expect(result, isA<Success<EpgGuide>>());
    });

    test('fails when offline with nothing cached', () async {
      remote.fail = true;

      final result = await repository()
          .loadGuide('https://example.test/g.xml', channelIds: {'a'});

      expect((result as FailureResult<EpgGuide>).failure, isA<EpgFailure>());
    });
  });
}
