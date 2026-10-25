import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/settings/domain/models/app_info.dart';

enum AppThemeMode { system, light, dark }

abstract interface class SettingsRepository {
  AppThemeMode getThemeMode();

  Future<Result<void>> setThemeMode(AppThemeMode mode);

  Future<Result<void>> clearCache();

  Future<Result<AppInfo>> getAppInfo();
}
