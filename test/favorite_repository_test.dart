import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/data/datasources/favorite_local_data_source.dart';
import 'package:ip_tv/features/favorites/data/repositories/favorite_repository_impl.dart';

void main() {
  late Directory directory;
  late Box<String> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('iptv_favorites_test_');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('favorites_test');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('persists a channel snapshot and removes it by ID', () async {
    const channel = Channel(
      id: 'news-one',
      name: 'News One',
      streamUrl: 'https://example.test/news.m3u8',
      category: 'News',
    );
    final repository = FavoriteRepositoryImpl(HiveFavoriteLocalDataSource(box));

    expect(await repository.addFavorite(channel), isA<Success<void>>());
    final loaded = await repository.getFavorites();
    expect(loaded, isA<Success<List<Channel>>>());
    expect((loaded as Success<List<Channel>>).value, [channel]);
    expect(
      await repository.removeFavorite(channel.id),
      isA<Success<void>>(),
    );
    final empty = await repository.getFavorites();
    expect(empty, isA<Success<List<Channel>>>());
    expect((empty as Success<List<Channel>>).value, isEmpty);
  });

  test('returns a cache failure for corrupt favorite data', () async {
    await box.put('broken', 'not-json');
    final repository = FavoriteRepositoryImpl(HiveFavoriteLocalDataSource(box));

    final result = await repository.getFavorites();

    expect((result as FailureResult<List<Channel>>).failure, isA<CacheFailure>());
  });
}