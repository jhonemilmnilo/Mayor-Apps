import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_constants.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
