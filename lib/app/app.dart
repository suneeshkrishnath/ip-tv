import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/app/router.dart';
import 'package:ip_tv/core/theme/app_theme.dart';
import 'package:ip_tv/features/settings/application/settings_providers.dart';
import 'package:ip_tv/features/settings/domain/repositories/settings_repository.dart';

class IptvApp extends ConsumerWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = switch (ref.watch(themeModeProvider)) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
    return MaterialApp.router(
      title: 'Nerampokku',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: appRouter,
    );
  }
}
