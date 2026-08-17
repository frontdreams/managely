import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../../../models/scenario.dart';
import '../../../core/services/service_providers.dart';

/// Holds the signed-in user's [UserProfile], hydrated from and persisted to
/// their Firestore document (`/users/{uid}`). Re-created whenever the signed
/// in user changes (see [userProfileProvider]).
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._ref, this._uid) : super(const UserProfile()) {
    if (_uid != null) _hydrate();
  }

  final Ref _ref;
  final String? _uid;

  Future<void> _hydrate() async {
    final uid = _uid;
    if (uid == null) return;
    final repo = _ref.read(firestoreUserRepositoryProvider);
    final loaded = await repo.loadProfile(uid);
    final authName = _ref.read(firebaseAuthProvider).currentUser?.displayName;

    if (loaded != null) {
      state = (authName != null &&
              authName.isNotEmpty &&
              authName != loaded.name)
          ? loaded.copyWith(name: authName)
          : loaded;
      return;
    }

    // Brand-new account: seed a fresh profile (using the auth display name,
    // if any) and persist it immediately so the doc exists going forward.
    final seeded = UserProfile(
      name: (authName != null && authName.isNotEmpty) ? authName : 'You',
      isHydrated: true,
    );
    state = seeded;
    await repo.saveProfile(uid, seeded);
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    await _ref.read(firestoreUserRepositoryProvider).saveProfile(uid, state);
  }

  Future<void> completeOnboarding(List<ManagerSkill> focusSkills) async {
    state = state.copyWith(
      onboardingComplete: true,
      focusSkills: focusSkills,
    );
    await _persist();
  }

  Future<void> toggleTheme(bool isDark) async {
    state = state.copyWith(themeIsDark: isDark);
    await _persist();
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _persist();
  }

  /// Called after a conversation is evaluated — nudges the relevant skill
  /// scores toward the session's results and bumps aggregate stats.
  Future<void> recordSessionResult(Map<ManagerSkill, int> sessionScores) async {
    final updated = Map<ManagerSkill, int>.from(state.skillScores);

    sessionScores.forEach((skill, newScore) {
      final current = updated[skill] ?? 50;
      // Blend: 65% history, 35% latest session — smooths growth over time.
      updated[skill] = ((current * 0.65) + (newScore * 0.35)).round();
    });

    state = state.copyWith(
      skillScores: updated,
      totalConversations: state.totalConversations + 1,
      completedScenarios: state.completedScenarios + 1,
      currentStreak: state.currentStreak + 1,
    );
    await _persist();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  return UserProfileNotifier(ref, uid);
});
