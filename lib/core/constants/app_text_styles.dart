import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Standard typography styles for DOODLEDRY.
class AppTextStyles {
  // Headings
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleSmall = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  // Vitals Digits
  static TextStyle vitalValueLarge = GoogleFonts.outfit(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
  );

  static TextStyle vitalValueMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle vitalUnit = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Captions & Labels
  static TextStyle label = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
