import 'package:flutter/material.dart';

class MekongColors {
  // Exact palette specified in page 1
  static const Color paper = Color(0xFFF7F0E3);     // screens background
  static const Color card = Color(0xFFFFFAF1);      // cards background
  static const Color riverGreen = Color(0xFF2D4A36);// headers & primary buttons
  static const Color clay = Color(0xFFB4472A);      // plan, Ask CTA
  static const Color deltaBlue = Color(0xFF3E6C85); // map, notes, cultural note
  static const Color mustard = Color(0xFFE6A82E);   // scan, alerts, status
  static const Color straw = Color(0xFFE3CBA3);     // culture tile, tags
  static const Color ink = Color(0xFF2A2119);       // text & icons
  static const Color muted = Color(0xFF7A7067);     // secondary text
  static const Color divider = Color(0xFFEADBCE);   // borders & dividers
  static const Color stubBorder = Color(0xFFC9BCA8);// dashed stub border
}

class MekongTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: MekongColors.paper,
      primaryColor: MekongColors.riverGreen,
      colorScheme: const ColorScheme.light(
        primary: MekongColors.riverGreen,
        secondary: MekongColors.clay,
        surface: MekongColors.card,
        background: MekongColors.paper,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: MekongColors.ink,
        onBackground: MekongColors.ink,
      ),
      fontFamily: 'Nunito Sans',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: MekongColors.ink,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: MekongColors.ink,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MekongColors.ink,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MekongColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: MekongColors.ink,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: MekongColors.ink,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: MekongColors.muted,
        ),
      ),
    );
  }
}
