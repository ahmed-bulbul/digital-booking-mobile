import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF006950);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFF89F8D0);
  static const Color secondary = Color(0xFF4C6359);
  static const Color surface = Color(0xFFF5FBF7);
  static const Color onSurface = Color(0xFF191C1B);
  static const Color onSurfaceVariant = Color(0xFF3F4946);
  static const Color outline = Color(0xFF6F7975);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Color(0xFF002117),
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFCEE9DF),
        onSecondaryContainer: Color(0xFF092019),
        tertiary: Color(0xFF3D6374),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFC1E8FC),
        onTertiaryContainer: Color(0xFF001F2B),
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: Color(0xFFBFC9C4),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFF2D3130),
        onInverseSurface: Color(0xFFEBF2EE),
        inversePrimary: Color(0xFF6CDBBB),
        surfaceTint: primary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFC9C4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFC9C4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFBFC9C4), width: 0.5),
        ),
        color: Colors.white,
      ),
    );
  }
}
