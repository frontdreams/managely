import 'package:flutter/material.dart';

/// Managely's monochrome palette — pure black and white with grayscale
/// tints, no brand hue. Replaces the original navy/gold palette, which is
/// preserved (unused) in `app_colors_legacy.dart`/`AppColorsLegacy` as a
/// backup — see that file's doc comment to revert.
///
/// [primary] and [accent] are both black here since this theme has no
/// second hue to pair them against, unlike the original navy+gold design.
/// Anywhere that needs a light background under a dark ([primary]/[accent])
/// foreground still works correctly — [primaryLight]/[accentLight] are
/// light grays, not light-on-dark inversions — but composed pairings that
/// specifically need light-on-dark (e.g. a button's white label on a black
/// fill) hardcode `Colors.white` directly in `app_theme.dart` rather than
/// reusing [primary], since [primary] itself is dark here.
class AppColors {
  AppColors._();

  // Brand — monochrome
  static const Color primary = Color(0xFF000000);
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color primaryLight = Color(0xFFF2F2F5);

  static const Color accent = Color(0xFF000000);
  static const Color accentLight = Color(0xFFF2F2F5);

  // Semantic — deliberately kept in color even in an otherwise monochrome
  // theme: red/amber/green still carry meaning at a glance (errors,
  // warnings, success) that grayscale alone would blunt.
  static const Color success = Color(0xFF1FAA6D);
  static const Color warning = Color(0xFFE8A93B);
  static const Color danger = Color(0xFFE05A5A);

  // Neutrals — light
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F8);
  static const Color borderLight = Color(0xFFE5E5E8);
  static const Color textPrimaryLight = Color(0xFF0A0A0A);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Text sitting directly on the bgLight background (outside cards).
  // bgLight is white here, so "on brand" text is just the normal dark/gray
  // text colors rather than the white/white70 the navy version needed.
  static const Color textOnBrand = Color(0xFF0A0A0A);
  static const Color textOnBrandMuted = Color(0xFF6B7280);

  // Neutrals — dark (inverted monochrome, for the in-app Dark Theme toggle)
  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color borderDark = Color(0xFF2E2E2E);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Muted "paint box" accents — the one deliberate spot of color in an
  // otherwise monochrome theme. Used for small icon chips (a settings row,
  // a feedback section, an info block, a skill/category badge) so a
  // stacked list of icons reads apart at a glance instead of blurring
  // into identical black squares. Kept soft/desaturated on purpose, and
  // never red — red stays reserved for [danger] so it isn't diluted into
  // decoration.
  static const Color iconBlue = Color(0xFF7C93C9);
  static const Color iconTeal = Color(0xFF6FAFA0);
  static const Color iconPurple = Color(0xFF9C8CC4);
  static const Color iconAmber = Color(0xFFC9A268);
  static const Color iconPink = Color(0xFFC98CA0);
  static const Color iconGreen = Color(0xFF8AAE7E);

  // Skill accent colors — reuse the muted palette above (one shade per
  // skill) instead of the flat black this theme started with, so skill
  // bars/badges/chips stay visually distinguishable from each other.
  static const Color skillEmpathy = iconPink;
  static const Color skillClarity = iconBlue;
  static const Color skillAssertiveness = iconAmber;
  static const Color skillActiveListening = iconTeal;
  static const Color skillConflict = iconPurple;
  static const Color skillBoundary = iconGreen;

  /// Dark gradient — always paired with light/white text on top (e.g. the
  /// profile header card), so it stays a near-black gradient rather than
  /// inverting to light.
  static const List<Color> heroGradient = [
    Color(0xFF000000),
    Color(0xFF2B2B2B),
  ];

  /// Light gradient — always paired with dark ([primary]) text/icons on
  /// top (e.g. the "Premium scenario" lock banners), mirroring the
  /// original light-gold-with-dark-text pairing but in grayscale.
  static const List<Color> goldGradient = [
    Color(0xFFFAFAFA),
    Color(0xFFE3E3E6),
  ];
}
