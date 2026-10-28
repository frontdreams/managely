import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors [UserProfile.themeMode]/[UserProfile.languageOverride] in
/// device-local storage, independent of the signed-in user's Firestore
/// doc. Firestore stays the source of truth while signed in, but there's
/// no Firestore doc to read before a user signs in or right after they
/// sign out — without this, Welcome/Login/Onboarding would fall back to
/// the device's system theme and language instead of whatever the user
/// had last explicitly chosen in Preferences.
class LocalPrefsService {
  LocalPrefsService._();

  static const _themeModeKey = 'local_theme_mode';
  static const _languageOverrideKey = 'local_language_override';

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  static Future<void> saveLanguageOverride(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_languageOverrideKey);
    } else {
      await prefs.setString(_languageOverrideKey, languageCode);
    }
  }

  static Future<({ThemeMode themeMode, String? languageOverride})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_themeModeKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => ThemeMode.system,
    );
    return (
      themeMode: mode,
      languageOverride: prefs.getString(_languageOverrideKey),
    );
  }
}
