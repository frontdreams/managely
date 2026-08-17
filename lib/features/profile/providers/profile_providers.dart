import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../../../models/scenario.dart';
import '../../../core/services/service_providers.dart';

/// Holds the single [UserProfile] for this MVP (no auth/multi-user).
/// Persists key fields (onboarding, focus skills, theme, skill scores) via
/// [LocalStorageService].
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._ref) : super(const UserProfile()) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final storage = _ref.read(localStorageServiceProvider);
    final onboardingComplete = await storage.isOnboardingComplete();
    final focusSkills = await storage.loadFocusSkills();
    final name = await storage.loadUserName();
    final isDark = await storage.loadThemeDark();
    final notifications = await storage.loadNotificationsEnabled();
    final skillScores = await storage.loadSkillScores();

    state = state.copyWith(
      onboardingComplete: onboardingComplete,
      focusSkills: focusSkills,
      name: name ?? state.name,
      themeIsDark: isDark,
      notificationsEnabled: notifications,
      skillScores: skillScores ?? state.skillScores,
    );
  }

  Future<void> completeOnboarding(List<ManagerSkill> focusSkills) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.setOnboardingComplete(true);
    await storage.saveFocusSkills(focusSkills);
    state = state.copyWith(
      onboardingComplete: true,
      focusSkills: focusSkills,
    );
  }

  Future<void> toggleTheme(bool isDark) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.saveThemeDark(isDark);
    state = state.copyWith(themeIsDark: isDark);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.saveNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// Called after a conversation is evaluated — nudges the relevant skill
  /// scores toward the session's results and bumps aggregate stats.
  Future<void> recordSessionResult(Map<ManagerSkill, int> sessionScores) async {
    final storage = _ref.read(localStorageServiceProvider);
    final updated = Map<ManagerSkill, int>.from(state.skillScores);

    sessionScores.forEach((skill, newScore) {
      final current = updated[skill] ?? 50;
      // Blend: 65% history, 35% latest session — smooths growth over time.
      updated[skill] = ((current * 0.65) + (newScore * 0.35)).round();
    });

    await storage.saveSkillScores(updated);

    state = state.copyWith(
      skillScores: updated,
      totalConversations: state.totalConversations + 1,
      completedScenarios: state.completedScenarios + 1,
      currentStreak: state.currentStreak + 1,
    );
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});
