import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDeep = Color(0xFF07131F);
  static const Color surface = Color(0xFF102235);
  static const Color surfaceAlt = Color(0xFF173047);
  static const Color primary = Color(0xFF35E0A1);
  static const Color accent = Color(0xFF4AC7FF);
  static const Color textMuted = Color(0xFF9EB4C6);

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        onPrimary: Color(0xFF052015),
        onSecondary: Color(0xFF07131F),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.82),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: accent.withValues(alpha: 0.22)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: const Color(0xFF062113),
          backgroundColor: primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: textTheme.bodySmall,
        hintStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.9)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}
