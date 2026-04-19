import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color frostyWhite = Color(0xFFF4FAF6);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color spaceNavy = Color(0xFF064E3B);
  static const Color electricTeal = Color(0xFF10B981);
  static const Color textCharcoal = Color(0xFF334155);
  static const Color errorRed = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: frostyWhite,
      primaryColor: electricTeal,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: spaceNavy,
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: spaceNavy,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          color: spaceNavy,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: -2.0,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textCharcoal,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textCharcoal,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: textCharcoal,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}