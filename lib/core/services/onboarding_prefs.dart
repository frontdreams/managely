import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHasCompletedOnboardingKey = 'has_completed_onboarding';

/// Whether this device has ever completed the onboarding intro. Checked
/// once at startup, independently of auth state, so onboarding is a
/// one-time-per-device gate: skip it on every later launch, whether the
/// user ends up on the login screen or straight into a signed-in session.
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kHasCompletedOnboardingKey) ?? false;
});

Future<void> markOnboardingComplete(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kHasCompletedOnboardingKey, true);
  ref.invalidate(hasCompletedOnboardingProvider);
}
