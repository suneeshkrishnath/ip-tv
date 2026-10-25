import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/core/storage/hive_providers.dart';
import 'package:ip_tv/core/cache/logo_cache_manager.dart';
import 'package:ip_tv/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ip_tv/features/settings/domain/models/app_info.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    settingsBox: ref.watch(settingsBoxProvider),
    playlistBox: ref.watch(playlistBoxProvider),
    epgBox: ref.watch(epgBoxProvider),
    clearLogoCache: logoCacheManager.emptyCache,
  );
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => ref.read(settingsRepositoryProvider).getThemeMode();

  Future<AppFailure?> update(AppThemeMode mode) async {
    final result = await ref
        .read(settingsRepositoryProvider)
        .setThemeMode(mode);
    switch (result) {
      case Success<void>():
        state = mode;
        return null;
      case FailureResult<void>(:final failure):
        return failure;
    }
  }
}

final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final result = await ref.read(settingsRepositoryProvider).getAppInfo();
  return switch (result) {
    Success<AppInfo>(:final value) => value,
    FailureResult<AppInfo>(:final failure) => throw failure,
  };
});
