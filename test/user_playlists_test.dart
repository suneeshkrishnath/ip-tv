import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:ip_tv/features/playlists/data/repositories/hive_user_playlists_repository.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/user_playlists_repository.dart';
import 'package:ip_tv/features/playlists/presentation/manage_playlists_screen.dart';

class _FakeCache implements PlaylistLocalDataSource {
  final removed = <String>[];

  @override
  Future<void> cache(Playlist playlist) async {}

  @override
  Future<Playlist?> get(String playlistId) async => null;

  @override
  Future<void> remove(String playlistId) async => removed.add(playlistId);
}

List<PlaylistSource> _sources(Result<List<PlaylistSource>> result) =>
    (result as Success<List<PlaylistSource>>).value;

void main() {
  late Directory directory;
  late Box<String> box;
  late _FakeCache cache;
  late HiveUserPlaylistsRepository repository;
  var tick = 0;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('iptv_sources_test_');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('sources_test');
    cache = _FakeCache();
    tick = 0;
    repository = HiveUserPlaylistsRepository(
      box,
      cache,
      clock: () => DateTime.fromMicrosecondsSinceEpoch(++tick),
    );
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('adds playlists with unique ids and persists them', () async {
    await repository.add(name: ' One ', url: 'https://example.test/a.m3u');
    await repository.add(name: 'Two', url: 'http://example.test/b.m3u');

    await box.close();
    final reopened = HiveUserPlaylistsRepository(
      await Hive.openBox<String>('sources_test'),
      cache,
    );
    final sources = _sources(await reopened.getAll());
    expect(sources.map((s) => s.name), ['One', 'Two']);
    expect(sources.first.id, isNot(sources.last.id));
  });

  test('rejects an empty name and invalid URLs', () async {
    for (final (name, url) in [
      ('', 'https://example.test/a.m3u'),
      ('Name', 'not a url'),
      ('Name', 'ftp://example.test/a.m3u'),
    ]) {
      final result = await repository.add(name: name, url: url);
      expect(
        (result as FailureResult<PlaylistSource>).failure,
        isA<PlaylistValidationFailure>(),
      );
    }
    expect(_sources(await repository.getAll()), isEmpty);
  });

  test('edits a playlist and clears its cache only when the URL changes',
      () async {
    final added = (await repository.add(
      name: 'One',
      url: 'https://example.test/a.m3u',
    ) as Success<PlaylistSource>)
        .value;

    await repository.edit(
      id: added.id,
      name: 'Renamed',
      url: 'https://example.test/a.m3u',
    );
    expect(cache.removed, isEmpty);

    await repository.edit(
      id: added.id,
      name: 'Renamed',
      url: 'https://example.test/b.m3u',
    );
    expect(cache.removed, [added.id]);
    final sources = _sources(await repository.getAll());
    expect(sources.single.name, 'Renamed');
    expect(sources.single.url, 'https://example.test/b.m3u');
  });

  test('editing a missing playlist fails', () async {
    final result = await repository.edit(
      id: 'missing',
      name: 'Name',
      url: 'https://example.test/a.m3u',
    );
    expect(result, isA<FailureResult<PlaylistSource>>());
  });

  test('deletes a playlist and its cache', () async {
    final added = (await repository.add(
      name: 'One',
      url: 'https://example.test/a.m3u',
    ) as Success<PlaylistSource>)
        .value;

    await repository.delete(added.id);

    expect(_sources(await repository.getAll()), isEmpty);
    expect(cache.removed, [added.id]);
  });

  test('returns a failure for corrupt stored data', () async {
    await box.put('user_playlists', 'not json');
    expect(
      await repository.getAll(),
      isA<FailureResult<List<PlaylistSource>>>(),
    );
  });

  test('notifier lists built-in and saved playlists and resets selection',
      () async {
    final container = ProviderContainer(
      overrides: [userPlaylistsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(playlistSourcesProvider.future);

    final notifier = container.read(playlistSourcesProvider.notifier);
    expect(await notifier.add(name: 'Mine', url: 'https://example.test/m.m3u'),
        isNull);
    final list = container.read(playlistSourcesProvider).value!;
    expect(list.map((s) => s.name), ['Malayalam', 'All channels', 'Mine']);

    final mine = list.last;
    container.read(selectedPlaylistSourceProvider.notifier).select(mine);
    await notifier.delete(mine);

    expect(container.read(playlistSourcesProvider).value, hasLength(2));
    expect(container.read(selectedPlaylistSourceProvider).id, 'malayalam');
  });

  testWidgets('screen adds a playlist and shows validation errors',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        userPlaylistsRepositoryProvider.overrideWithValue(_MemorySources()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ManagePlaylistsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Mine');
    await tester.enterText(find.widgetWithText(TextField, 'M3U URL'), 'bad');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid http or https playlist URL.'),
        findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'M3U URL'),
      'https://example.test/m.m3u',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Mine'), findsOneWidget);
  });
}

class _MemorySources implements UserPlaylistsRepository {
  final items = <PlaylistSource>[];

  @override
  Future<Result<List<PlaylistSource>>> getAll() async => Success([...items]);

  @override
  Future<Result<PlaylistSource>> add({
    required String name,
    required String url,
  }) async {
    if (!url.startsWith('https://')) {
      return const FailureResult(
        PlaylistValidationFailure('Enter a valid http or https playlist URL.'),
      );
    }
    final source = PlaylistSource(id: 'u${items.length}', name: name, url: url);
    items.add(source);
    return Success(source);
  }

  @override
  Future<Result<PlaylistSource>> edit({
    required String id,
    required String name,
    required String url,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> delete(String id) async => throw UnimplementedError();
}
