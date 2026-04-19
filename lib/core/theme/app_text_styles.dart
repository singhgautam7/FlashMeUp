import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography definitions for FlashMeUp.
/// Mirrors Kuber's AppTextStyles for full consistency.
class AppTextStyles {
  static TextStyle get inter => GoogleFonts.inter();

  static TextStyle get regular => GoogleFonts.inter(fontWeight: FontWeight.w400);
  static TextStyle get medium => GoogleFonts.inter(fontWeight: FontWeight.w500);
  static TextStyle get semiBold => GoogleFonts.inter(fontWeight: FontWeight.w600);
  static TextStyle get bold => GoogleFonts.inter(fontWeight: FontWeight.w700);
  static TextStyle get extraBold => GoogleFonts.inter(fontWeight: FontWeight.w800);

  /// Returns the default TextTheme for the app based on Inter.
  static TextTheme getTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base);
  }
}
