import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Fraunces (Display & Titles - Variable Soft Serif)
  static TextStyle get displayLarge => GoogleFonts.fraunces(
    fontSize: 40.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5 / 100,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.fraunces(
    fontSize: 32.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.25 / 100,
    height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.fraunces(
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.25 / 100,
    height: 1.2,
  );

  static TextStyle get titleLarge => GoogleFonts.fraunces(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.25 / 100,
    height: 1.25,
  );

  static TextStyle get titleMedium => GoogleFonts.fraunces(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.25 / 100,
    height: 1.3,
  );

  // Inter (Body, Labels & Functional UI - Utilitarian Sans-Serif)
  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.38,
  );

  static TextStyle get sectionLabel => GoogleFonts.inter(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 13.0 * (6.0 / 100),
    height: 1.38,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.47,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.43,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.38,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 12.0 * (2.0 / 100),
    height: 1.33,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    letterSpacing: 12.0 * (1.0 / 100),
    height: 1.33,
  );

  static TextStyle get timerLarge => GoogleFonts.inter(
    fontSize: 40.0,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 1.0,
    height: 1.1,
  );

  static TextStyle get timerSmall => GoogleFonts.inter(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 0.5,
    height: 1.17,
  );
}
