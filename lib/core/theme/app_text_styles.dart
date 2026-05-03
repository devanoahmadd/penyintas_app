import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Plus Jakarta Sans ─────────────────────────────────────────────────────

  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 64,
        height: 0.98,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        height: 1.10,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        height: 1.30,
        fontWeight: FontWeight.w600,
      );

  // ── Inter Tight ───────────────────────────────────────────────────────────

  static TextStyle get body => GoogleFonts.interTight(
        fontSize: 16,
        height: 1.50,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => GoogleFonts.interTight(
        fontSize: 14,
        height: 1.40,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get label => GoogleFonts.interTight(
        fontSize: 14,
        height: 1.30,
        fontWeight: FontWeight.w600,
      );

  // ── JetBrains Mono ────────────────────────────────────────────────────────

  static TextStyle get caption => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        height: 1.30,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericSm => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        height: 1.0,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericMd => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        height: 1.0,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericLg => GoogleFonts.jetBrainsMono(
        fontSize: 32,
        height: 1.0,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
