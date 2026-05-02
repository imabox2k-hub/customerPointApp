import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary   = Color(0xFFB85C8A);
  static const Color primaryDk = Color(0xFFC96E6E);
  static const Color bg        = Color(0xFFFDF6F0);
  static const Color card      = Colors.white;
  static const Color accent    = Color(0xFFFFD6E7);
  static const Color textDark  = Color(0xFF3A2E2E);
  static const Color textGrey  = Color(0xFF9E8E8E);
  static const Color success   = Color(0xFF27AE60);
  static const Color error     = Color(0xFFE74C3C);
  static const Color gold      = Color(0xFFFFB347);

  static final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFC96E6E), Color(0xFFB85C8A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          background: bg,
        ),
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 28, fontWeight: FontWeight.w600, color: textDark,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w600, color: textDark,
          ),
          bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: textDark),
          bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: textDark),
          labelSmall: GoogleFonts.dmSans(fontSize: 11, color: textGrey),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0DCE8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0DCE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: GoogleFonts.dmSans(color: textGrey, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
            elevation: 0,
          ),
        ),
      );
}
