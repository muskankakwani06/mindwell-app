import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colours ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF2D9F6B); 
  static const Color primaryLight   = Color(0xFFE8F5EE);
  static const Color accent         = Color(0xFFD4845A); 
  static const Color background     = Color(0xFFF8F9F5); 
  static const Color cardColor      = Color(0xFFFFFFFF);
  static const Color foreground     = Color(0xFF0F2118); 
  static const Color muted          = Color(0xFFF1F3EE);
  static const Color mutedFg        = Color(0xFF6D7E75); 
  static const Color border         = Color(0xFFE5E9DF);
  static const Color destructive    = Color(0xFFDC3545);

  // Gradient card colours (iOS Pastel Style)
  static const Color sageBg         = Color(0xFFE8F5E9);
  static const Color warmBg         = Color(0xFFFFF3E0);
  static const Color lavenderBg     = Color(0xFFF3E5F5);
  static const Color skyBg          = Color(0xFFE1F5FE);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: cardColor,
        error: destructive,
        onPrimary: Colors.white,
        onSurface: foreground,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(fontSize: 34, color: foreground),
        displayMedium: GoogleFonts.dmSerifDisplay(fontSize: 28, color: foreground),
        displaySmall: GoogleFonts.dmSerifDisplay(fontSize: 22, color: foreground),
        headlineMedium: GoogleFonts.dmSerifDisplay(fontSize: 20, color: foreground),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: foreground),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: foreground),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: foreground),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: mutedFg),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withOpacity(0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSerifDisplay(fontSize: 18, color: foreground),
        iconTheme: const IconThemeData(color: foreground),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 2,
          shadowColor: primary.withOpacity(0.3),
        ),
      ),
    );
  }
}
