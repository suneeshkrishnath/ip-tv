import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/settings/application/settings_providers.dart';
import 'package:ip_tv/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ip_tv/features/settings/domain/models/app_info.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';
import 'package:ip_tv/features/settings/presentation/settings_screen.dart';
import 'package:ip_tv/features/playlists/application/playlist_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  AppThemeMode mode = AppThemeMode.system;
  bool logoCacheCleared = false;

  @override
  AppThemeMode getThemeMode() => mode;

  @override
  Future<Result<void>> setThemeMode(AppThemeMode value) async {
    mode = value;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearCache() async {
    logoCacheCleared = true;
    return const Success(null);
  }

  @override
  Future<Result<AppInfo>> getAppInfo() async =>
      const Success(AppInfo(version: '0.4.1', buildNumber: '5'));
}

void main() {
  group('SettingsRepositoryImpl', () {
    late Directory directory;
    late Box<String> settings;
    late Box<String> playlists;
    late Box<String> epg;
    late Box<String> favorites;
    late Box<String> history;
    var logoCleared = false;

    SettingsRepositoryImpl repository() => SettingsRepositoryImpl(
      settingsBox: settings,
      playlistBox: playlists,
      epgBox: epg,
      clearLogoCache: () async => logoCleared = true,
      appInfoLoader: () async =>
          const AppInfo(version: '0.4.1', buildNumber: '5'),
    );

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('iptv_settings_test_');
      Hive.init(directory.path);
      settings = await Hive.openBox<String>('settings_test');
      playlists = await Hive.openBox<String>('playlists_test');
      epg = await Hive.openBox<String>('epg_test');
      favorites = await Hive.openBox<String>('favorites_test');
      history = await Hive.openBox<String>('history_test');
      logoCleared = false;
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('defaults to system and persists theme selection', () async {
      expect(repository().getThemeMode(), AppThemeMode.system);
      await repository().setThemeMode(AppThemeMode.light);
      await settings.close();
      settings = await Hive.openBox<String>('settings_test');

      expect(repository().getThemeMode(), AppThemeMode.light);
    });

    test('clears only cached playlists, guides and logos', () async {
      await settings.put('theme_mode', 'dark');
      await settings.put('disclaimer_accepted', 'true');
      await playlists.put('cached', 'playlist');
      await epg.put('cached', 'guide');
      await favorites.put('saved', 'favorite');
      await history.put('recent', 'history');

      final result = await repository().clearCache();

      expect(result, isA<Success<void>>());
      expect(playlists.isEmpty, isTrue);
      expect(epg.isEmpty, isTrue);
      expect(logoCleared, isTrue);
      expect(settings.get('theme_mode'), 'dark');
      expect(settings.get('disclaimer_accepted'), 'true');
      expect(favorites.get('saved'), 'favorite');
      expect(history.get('recent'), 'history');
    });

    test('returns app version and build number', () async {
      final result = await repository().getAppInfo();

      expect(
        (result as Success<AppInfo>).value,
        const AppInfo(version: '0.4.1', buildNumber: '5'),
      );
    });
  });

  testWidgets('Settings shows theme, refresh, cache, and app info', (
    tester,
  ) async {
    final repository = _FakeSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          playlistRepositoryProvider.overrideWithValue(
            _EmptyPlaylistRepository(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Refresh current playlist'), findsOneWidget);
    expect(find.text('Clear cached data'), findsOneWidget);
    expect(find.text('Version 0.4.1 (5)'), findsOneWidget);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(repository.mode, AppThemeMode.light);

    await tester.tap(find.text('Clear cached data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    expect(repository.logoCacheCleared, isTrue);
    expect(find.text('Cached data cleared.'), findsOneWidget);
  });
}

class _EmptyPlaylistRepository implements PlaylistRepository {
  @override
  Future<Result<Playlist>> loadPlaylist(PlaylistSource source) async =>
      throw UnimplementedError();

  @override
  Future<Result<Playlist?>> getCachedPlaylist(String playlistId) async =>
      const Success(null);
}
