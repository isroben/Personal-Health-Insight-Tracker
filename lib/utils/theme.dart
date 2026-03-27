import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette ──
  static const Color primaryBlue = Color(0xFF4C9EEB); 
  static const Color surfaceBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0A000000);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color boxcolor = Color(0xFFECF2F8);

  // ── Light Theme ──
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surfaceBackground,
        onSurface: textMain,
        onSurfaceVariant: textSecondary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textMain,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceBackground,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textMain),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: boxcolor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
