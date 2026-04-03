import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnowscapeColors {
  static const primary = Color(0xFF005DA6);
  static const primaryContainer = Color(0xFF54A3FF);
  static const secondary = Color(0xFF4555A8);
  static const surface = Color(0xFFF5F7F9);
  static const surfaceContainerLow = Color(0xFFEEF1F3);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHighest = Color(0xFFD9DDE0);
  static const onSurface = Color(0xFF2C2F31);
  static const onSurfaceVariant = Color(0xFF595C5E);
  static const tertiaryContainer = Color(0xFFDEF5F8);
  static const onTertiaryContainer = Color(0xFF495E60);
  static const error = Color(0xFFB31B25);
}

ThemeData createAgentTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: SnowscapeColors.surface,
    textTheme: GoogleFonts.beVietnamProTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 56,
        color: SnowscapeColors.onSurface,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: SnowscapeColors.onSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: SnowscapeColors.onSurface,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: SnowscapeColors.primary,
      secondary: SnowscapeColors.secondary,
      surface: SnowscapeColors.surface,
      onSurface: SnowscapeColors.onSurface,
    ),
  );
}
