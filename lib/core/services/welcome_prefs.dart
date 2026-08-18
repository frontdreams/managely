import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHasSeenWelcomeKey = 'has_seen_welcome';

/// Whether this device has ever finished the welcome intro. Checked once at
/// startup, independently of auth state, so the welcome screen is a
/// one-time-per-device gate: skip it on every later launch, whether the
/// user ends up on the login screen or straight into a signed-in session.
final hasSeenWelcomeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kHasSeenWelcomeKey) ?? false;
});

Future<void> markWelcomeSeen(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kHasSeenWelcomeKey, true);
  ref.invalidate(hasSeenWelcomeProvider);
}
