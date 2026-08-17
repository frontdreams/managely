import 'package:flutter/material.dart';

/// Managely's brand palette — calm, intelligent, trustworthy.
/// Primary is a deep indigo/blue (leadership, trust); accent is a warm
/// teal-green (growth). Kept deliberately restrained for a premium feel.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F5FF7); // indigo-blue
  static const Color primaryDark = Color(0xFF3A47D1);
  static const Color primaryLight = Color(0xFFEAECFF);

  static const Color accent = Color(0xFF19B39A); // growth teal
  static const Color accentLight = Color(0xFFE1F7F3);

  // Semantic
  static const Color success = Color(0xFF1FAA6D);
  static const Color warning = Color(0xFFE8A93B);
  static const Color danger = Color(0xFFE05A5A);

  // Neutrals — light
  static const Color bgLight = Color(0xFFF7F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE7E9F3);
  static const Color textPrimaryLight = Color(0xFF1B1D2A);
  static const Color textSecondaryLight = Color(0xFF6B7086);

  // Neutrals — dark
  static const Color bgDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1A1D29);
  static const Color borderDark = Color(0xFF2B2F40);
  static const Color textPrimaryDark = Color(0xFFF2F3F8);
  static const Color textSecondaryDark = Color(0xFF9CA0B5);

  // Skill accent colors (used in progress bars / chips)
  static const Color skillEmpathy = Color(0xFFE0679B);
  static const Color skillClarity = Color(0xFF4F5FF7);
  static const Color skillAssertiveness = Color(0xFFE8A93B);
  static const Color skillActiveListening = Color(0xFF19B39A);
  static const Color skillConflict = Color(0xFF8B6BE0);
  static const Color skillBoundary = Color(0xFF4BA0E0);

  static const List<Color> heroGradient = [
    Color(0xFF4F5FF7),
    Color(0xFF6C7BFF),
  ];
}
