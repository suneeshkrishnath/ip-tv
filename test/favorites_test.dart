import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/favorites/data/repositories/hive_favorites_repository.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:ip_tv/features/favorites/presentation/favorites_screen.dart';

const _news = Channel(
  id: 'news',
  name: 'Example News',
  streamUrl: 'https://example.test/news.m3u8',
);
const _sports = Channel(
  id: 'sports',
  name: 'Example Sports',
  streamUrl: 'https://example.test/sports.m3u8',
);

class _MemoryFavorites implements FavoritesRepository {
  _MemoryFavorites(this.items);

  final List<Channel> items;

  @override
  Future<Result<List<Channel>>> getFavorites() async => Success([...items]);

  @override
  Future<Result<void>> addFavorite(Channel channel) async {
    items.insert(0, channel);
    return const Success(null);
  }

  @override
  Future<Result<void>> removeFavorite(String channelId) async {
    items.removeWhere((channel) => channel.id == channelId);
    return const Success(null);
  }
}

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

  test('adds, orders, persists across reopen, and removes favorites', () async {
    final repository = HiveFavoritesRepository(box);
    await repository.addFavorite(_news);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.addFavorite(_sports);

    var result = await repository.getFavorites();
    expect((result as Success<List<Channel>>).value, [_sports, _news]);

    await box.close();
    final reopened = HiveFavoritesRepository(
      await Hive.openBox<String>('favorites_test'),
    );
    result = await reopened.getFavorites();
    expect((result as Success<List<Channel>>).value, [_sports, _news]);

    await reopened.removeFavorite(_sports.id);
    result = await reopened.getFavorites();
    expect((result as Success<List<Channel>>).value, [_news]);
  });

  test('returns a failure for corrupt stored data', () async {
    await box.put('bad', 'not json');
    final result = await HiveFavoritesRepository(box).getFavorites();
    expect(result, isA<FailureResult<List<Channel>>>());
  });

  test('notifier toggles a channel on and off', () async {
    final container = ProviderContainer(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(
          HiveFavoritesRepository(box),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(favoritesProvider.future);

    await container.read(favoritesProvider.notifier).toggle(_news);
    expect(container.read(isFavoriteProvider('news')), isTrue);

    await container.read(favoritesProvider.notifier).toggle(_news);
    expect(container.read(isFavoriteProvider('news')), isFalse);
  });

  testWidgets('favorites screen shows empty state and saved channels',
      (tester) async {
    final repository = _MemoryFavorites([_news]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [favoritesRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Example News'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
  });
}
