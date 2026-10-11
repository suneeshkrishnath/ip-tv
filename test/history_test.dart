import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:ip_tv/features/history/application/history_providers.dart';
import 'package:ip_tv/features/history/data/repositories/hive_history_repository.dart';
import 'package:ip_tv/features/history/domain/repositories/history_repository.dart';
import 'package:ip_tv/features/history/presentation/recently_watched_screen.dart';

Channel _channel(int index) => Channel(
      id: 'c$index',
      name: 'Channel $index',
      streamUrl: 'https://example.test/$index.m3u8',
    );

class _MemoryHistory implements HistoryRepository {
  _MemoryHistory([List<Channel>? items]) : items = items ?? [];

  final List<Channel> items;

  @override
  Future<Result<List<Channel>>> getRecent() async => Success([...items]);

  @override
  Future<Result<void>> record(Channel channel) async {
    items.insert(0, channel);
    return const Success(null);
  }
}

void main() {
  late Directory directory;
  late Box<String> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('iptv_history_test_');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('history_test');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('orders most recent first and moves repeats to the front', () async {
    final repository = HiveHistoryRepository(box);
    await repository.record(_channel(1));
    await repository.record(_channel(2));
    await repository.record(_channel(1));

    final result = await repository.getRecent();
    expect(
      (result as Success<List<Channel>>).value.map((c) => c.id),
      ['c1', 'c2'],
    );
  });

  test('keeps only the 20 most recent channels', () async {
    final repository = HiveHistoryRepository(box);
    for (var i = 0; i < 25; i++) {
      await repository.record(_channel(i));
    }

    final channels =
        ((await repository.getRecent()) as Success<List<Channel>>).value;
    expect(channels, hasLength(recentlyWatchedLimit));
    expect(channels.first.id, 'c24');
    expect(channels.last.id, 'c5');
  });

  test('persists across reopening the box', () async {
    await HiveHistoryRepository(box).record(_channel(1));
    await box.close();

    final reopened = HiveHistoryRepository(
      await Hive.openBox<String>('history_test'),
    );
    final channels =
        ((await reopened.getRecent()) as Success<List<Channel>>).value;
    expect(channels.single.id, 'c1');
  });

  test('returns a failure for corrupt stored data', () async {
    await box.put('recent', 'not json');
    final result = await HiveHistoryRepository(box).getRecent();
    expect(result, isA<FailureResult<List<Channel>>>());
  });

  test('notifier records a channel', () async {
    final container = ProviderContainer(
      overrides: [
        historyRepositoryProvider.overrideWithValue(_MemoryHistory()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(recentlyWatchedProvider.future);

    await container.read(recentlyWatchedProvider.notifier).record(_channel(1));

    expect(container.read(recentlyWatchedProvider).value, [_channel(1)]);
  });

  testWidgets('screen shows empty state and recent channels', (tester) async {
    Future<void> pump(_MemoryHistory history) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            historyRepositoryProvider.overrideWithValue(history),
            favoritesRepositoryProvider.overrideWithValue(_NoFavorites()),
          ],
          child: const MaterialApp(home: RecentlyWatchedScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(_MemoryHistory());
    expect(find.text('Nothing watched yet'), findsOneWidget);

    await pump(_MemoryHistory([_channel(1)]));
    expect(find.text('Channel 1'), findsOneWidget);
  });
}

class _NoFavorites implements FavoritesRepository {
  @override
  Future<Result<List<Channel>>> getFavorites() async => const Success([]);

  @override
  Future<Result<void>> addFavorite(Channel channel) async =>
      const Success(null);

  @override
  Future<Result<void>> removeFavorite(String channelId) async =>
      const Success(null);
}
