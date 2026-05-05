import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFF00E5FF),
      onPrimary: Color(0xFF000000),
      surface: Color(0xFF1A1A2E),
      onSurface: Color(0xFFE0E0E0),
      error: Color(0xFFCF6679),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
      ),
    );
  }
}
