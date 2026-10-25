import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/settings/domain/models/app_info.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required Box<String> settingsBox,
    required Box<String> playlistBox,
    required Box<String> epgBox,
    required Future<void> Function() clearLogoCache,
    Future<AppInfo> Function()? appInfoLoader,
  }) : _settingsBox = settingsBox,
       _playlistBox = playlistBox,
       _epgBox = epgBox,
       _clearLogoCache = clearLogoCache,
       _appInfoLoader = appInfoLoader ?? _loadAppInfo;

  static const _themeKey = 'theme_mode';

  final Box<String> _settingsBox;
  final Box<String> _playlistBox;
  final Box<String> _epgBox;
  final Future<void> Function() _clearLogoCache;
  final Future<AppInfo> Function() _appInfoLoader;

  @override
  AppThemeMode getThemeMode() => AppThemeMode.values.firstWhere(
    (mode) => mode.name == _settingsBox.get(_themeKey),
    orElse: () => AppThemeMode.system,
  );

  @override
  Future<Result<void>> setThemeMode(AppThemeMode mode) async {
    try {
      await _settingsBox.put(_themeKey, mode.name);
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to save the theme preference.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> clearCache() async {
    try {
      await _playlistBox.clear();
      await _epgBox.clear();
      await _clearLogoCache();
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure(
          'Unable to clear all cached media and guide data.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<Result<AppInfo>> getAppInfo() async {
    try {
      return Success(await _appInfoLoader());
    } on Object catch (error) {
      return FailureResult(
        UnknownFailure('Unable to read app version information.', cause: error),
      );
    }
  }

  static Future<AppInfo> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(version: info.version, buildNumber: info.buildNumber);
  }
}
