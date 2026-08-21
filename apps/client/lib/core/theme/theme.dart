import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AntigravityTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EA), 
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
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
        seedColor: const Color(0xFF6A0DAD), // Purple Accent
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E28), // Cards Surface (slight blueish dark)
        primary: const Color(0xFF8A2BE2), // Neon Purple
        secondary: const Color(0xFF00F5D4), // Cyan Glow
        tertiary: const Color(0xFF20C997), // Green success
        error: const Color(0xFFFF5C5C), // Red warnings
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A24), // Very subtle contrast from background
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.05),
        thickness: 1,
      ),
    );
  }
}
