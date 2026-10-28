import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/providers/profile_providers.dart';

/// The language code the app is actually showing right now — 'en' or
/// 'tr', never null. Mirrors exactly the same resolution main.dart's
/// `MaterialApp.locale`/`localeResolutionCallback` applies (explicit
/// override from Preferences first, else the device's own locale, falling
/// back to English for anything that isn't Turkish), kept here as the one
/// shared definition so other code — e.g. filtering stories by the
/// language they were posted in — can't drift out of sync with what's
/// actually on screen.
///
/// Reads the device locale via `platformDispatcher` rather than
/// `Localizations.localeOf(context)` so it works from plain providers
/// that have no BuildContext under a `Localizations` widget (this is
/// watched from main.dart itself, above that widget, as well as from
/// provider-only code like stories_providers.dart).
final resolvedLanguageCodeProvider = Provider<String>((ref) {
  final override = ref.watch(userProfileProvider.select((p) => p.languageOverride));
  if (override != null) return override;
  final deviceCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return deviceCode == 'tr' ? 'tr' : 'en';
});
