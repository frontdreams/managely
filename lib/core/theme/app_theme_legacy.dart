import 'package:flutter/material.dart';
import 'app_colors_legacy.dart';
import 'app_typography.dart';

class AppThemeLegacy {
  AppThemeLegacy._();

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 100;

  /// Pill-shaped, accent-yellow button used for the primary action on the
  /// onboarding, login, sign up and forgot password screens.
  static ButtonStyle get accentPillButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColorsLegacy.accent,
        foregroundColor: AppColorsLegacy.primary,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      );

  /// Unified snackbar look for the whole app — a compact, fully-rounded
  /// pill in a slightly translucent primary color, rather than Material's
  /// default full-width bar. Applies to every `SnackBar` automatically;
  /// use [AppSnackBar.show] to also get centered text.
  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        backgroundColor: AppColorsLegacy.primary.withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        width: 320,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColorsLegacy.accent,
      );

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColorsLegacy.primary,
      onPrimary: Colors.white,
      secondary: AppColorsLegacy.accent,
      onSecondary: AppColorsLegacy.primary,
      error: AppColorsLegacy.danger,
      onError: Colors.white,
      surface: AppColorsLegacy.surfaceLight,
      onSurface: AppColorsLegacy.textPrimaryLight,
    );

    final textTheme = AppTypography.textTheme(
      AppColorsLegacy.textPrimaryLight,
      AppColorsLegacy.textSecondaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsLegacy.bgLight,
      textTheme: textTheme,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      dividerColor: AppColorsLegacy.borderLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColorsLegacy.textOnBrand),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColorsLegacy.textOnBrand),
      ),
      cardTheme: CardThemeData(
        color: AppColorsLegacy.surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.16),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLegacy.primaryLight,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColorsLegacy.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLegacy.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLegacy.textPrimaryLight,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColorsLegacy.borderLight),
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLegacy.primary,
          textStyle: textTheme.titleMedium?.copyWith(color: AppColorsLegacy.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLegacy.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: AppColorsLegacy.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: AppColorsLegacy.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: AppColorsLegacy.primary, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLegacy.surfaceLight,
        selectedItemColor: AppColorsLegacy.primary,
        unselectedItemColor: AppColorsLegacy.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      splashFactory: InkRipple.splashFactory,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsLegacy.primary,
        linearTrackColor: AppColorsLegacy.primaryLight,
      ),
      snackBarTheme: _snackBarTheme,
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColorsLegacy.primary,
      onPrimary: Colors.white,
      secondary: AppColorsLegacy.accent,
      onSecondary: AppColorsLegacy.primary,
      error: AppColorsLegacy.danger,
      onError: Colors.white,
      surface: AppColorsLegacy.surfaceDark,
      onSurface: AppColorsLegacy.textPrimaryDark,
    );

    final textTheme = AppTypography.textTheme(
      AppColorsLegacy.textPrimaryDark,
      AppColorsLegacy.textSecondaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsLegacy.bgDark,
      textTheme: textTheme,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      dividerColor: AppColorsLegacy.borderDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsLegacy.bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColorsLegacy.textPrimaryDark),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColorsLegacy.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: AppColorsLegacy.borderDark),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLegacy.surfaceDark,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColorsLegacy.accent),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: const BorderSide(color: AppColorsLegacy.borderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLegacy.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLegacy.textPrimaryDark,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColorsLegacy.borderDark),
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLegacy.accent,
          textStyle: textTheme.titleMedium?.copyWith(color: AppColorsLegacy.accent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLegacy.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: AppColorsLegacy.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: AppColorsLegacy.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: AppColorsLegacy.accent, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLegacy.surfaceDark,
        selectedItemColor: AppColorsLegacy.accent,
        unselectedItemColor: AppColorsLegacy.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      splashFactory: InkRipple.splashFactory,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsLegacy.accent,
        linearTrackColor: AppColorsLegacy.surfaceDark,
      ),
      snackBarTheme: _snackBarTheme,
    );
  }
}
