/// ==========================================================================
/// theme.dart — App Theme (Colors, Text Styles, Shapes)
/// ==========================================================================
/// Defines a clean, calm, health-friendly color palette.
/// Primary: Soothing dark teal / green
/// Secondary: Soft blue
/// Includes accessible contrast ratios and large typography defaults.
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette ──
  static const Color primarySeed = Color(0xFF0D6E6E); // Deep calming teal
  static const Color secondaryColor = Color(0xFF4A90E2); // Soft blue
  static const Color errorColor = Color(0xFFE57373); // Soft red for severity

  // ── Light Theme ──
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeed,
        secondary: secondaryColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: primarySeed.withValues(alpha: 0.2),
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeed,
        secondary: secondaryColor,
        error: errorColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
