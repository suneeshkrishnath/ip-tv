import 'package:flutter/material.dart';

class AppTheme {
  static const _blue = Color(0xFF1E88E5);
  static const _cyan = Color(0xFF03DAC6);

  static final light = _createTheme(Brightness.light);
  static final dark = _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: brightness,
    ).copyWith(
      primary: _blue,
      secondary: _cyan,
      surface: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}