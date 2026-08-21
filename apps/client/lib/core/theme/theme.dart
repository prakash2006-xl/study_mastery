import 'package:flutter/material.dart';

class AntigravityTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EA), // Deep purple accent
        brightness: Brightness.light,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F0F13), // Deep cosmic black
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9D4EDD), // Neon Purple
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E24), // Glass pane surface
        primary: const Color(0xFF9D4EDD), // Neon Purple
        secondary: const Color(0xFF00F5D4), // Cyan Glow
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E24).withOpacity(0.6),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
    );
  }
}
