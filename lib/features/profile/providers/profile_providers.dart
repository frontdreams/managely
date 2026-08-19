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

    // Link this device's RevenueCat customer to the Firebase UID so
    // entitlements follow the account, not just the install.
    await _ref.read(revenueCatServiceProvider).logIn(uid);

    final repo = _ref.read(firestoreUserRepositoryProvider);
    final loaded = await repo.loadProfile(uid);
    final authUser = _ref.read(firebaseAuthProvider).currentUser;
    final authName = authUser?.displayName;
    final authPhoto = authUser?.photoURL;

    if (loaded != null) {
      var next = loaded;
      if (authName != null && authName.isNotEmpty && authName != loaded.name) {
        next = next.copyWith(name: authName);
      }
      // Only fill in the Google photo when the profile has none yet — a
      // user who picked their own photo shouldn't have it silently
      // replaced by their Google avatar on a later login.
      if ((loaded.photoUrl == null || loaded.photoUrl!.isEmpty) &&
          authPhoto != null &&
          authPhoto.isNotEmpty) {
        next = next.copyWith(photoUrl: authPhoto);
      }
      state = next;
      return;
    }

    // Brand-new account: seed a fresh profile (using the auth display name
    // and, for Google sign-ins, their Google profile photo) and persist it
    // immediately so the doc exists going forward.
    final seeded = UserProfile(
      name: (authName != null && authName.isNotEmpty) ? authName : 'You',
      photoUrl: (authPhoto != null && authPhoto.isNotEmpty) ? authPhoto : null,
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

  /// Re-fetches the profile from Firestore — used by pull-to-refresh.
  Future<void> refresh() => _hydrate();

  Future<void> completeOnboarding(List<ManagerSkill> focusSkills) async {
    state = state.copyWith(
      onboardingComplete: true,
      focusSkills: focusSkills,
    );
    await _persist();
  }

  /// Records the plan picked on the post-signup subscription screen —
  /// either an actual subscription, or an explicit "Continue for Free".
  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    state = state.copyWith(subscriptionTier: tier);
    await _persist();
  }

  /// Keeps [UserProfile.subscriptionTier] in sync with RevenueCat's actual
  /// entitlement status. This is the SOURCE OF TRUTH for whether someone
  /// is Premium once RevenueCat is wired up — driven by
  /// `customerInfoStreamProvider` in main.dart, which fires on purchase,
  /// renewal, expiration, refund, or a restore on another device. Prefer
  /// this over calling [setSubscriptionTier] directly from UI after a
  /// purchase completes; let the entitlement stream be authoritative.
  Future<void> syncSubscriptionFromEntitlement(bool isPremiumActive) async {
    final tier = isPremiumActive ? SubscriptionTier.premium : SubscriptionTier.free;
    if (tier == state.subscriptionTier) return;
    state = state.copyWith(subscriptionTier: tier);
    await _persist();
  }

  /// Sets each skill's starting score from the baseline Skills Assessment
  /// (the situational-judgment quiz taken right after onboarding) and marks
  /// it complete. Unlike [recordSessionResult], this REPLACES the scores
  /// outright rather than blending — there's no prior history yet worth
  /// blending against, this call *is* the real starting point.
  Future<void> setBaselineSkillScores(Map<ManagerSkill, int> scores) async {
    state = state.copyWith(
      skillScores: scores,
      skillsAssessmentComplete: true,
    );
    await _persist();
  }

  /// Call right before a free-tier user's conversation actually starts
  /// (not on completion — starting counts even if they abandon it, so the
  /// cap can't be gamed by retrying). Resets the ~30-day usage cycle if
  /// the last one has expired. No-op in the sense that premium users can
  /// call this too; it just won't be checked against the limit — see
  /// `UserProfile.hasReachedFreeConversationLimit`.
  Future<void> recordConversationStarted() async {
    final now = DateTime.now();
    final cycleStart = state.usageCycleStart;
    final cycleExpired =
        cycleStart == null || now.difference(cycleStart) > const Duration(days: 30);

    state = state.copyWith(
      freeConversationsUsedThisCycle:
          cycleExpired ? 1 : state.freeConversationsUsedThisCycle + 1,
      usageCycleStart: cycleExpired ? now : cycleStart,
    );
    await _persist();
  }

  /// Updates the editable fields on the "Edit Profile" screen.
  Future<void> updateProfile({String? name, ManagerLevel? level}) async {
    state = state.copyWith(name: name, level: level);
    await _persist();
  }

  /// Sets the profile photo — either a base64-encoded JPEG picked by the
  /// user, or an `http(s)` URL copied from a Google account.
  Future<void> updatePhoto(String photoUrl) async {
    state = state.copyWith(photoUrl: photoUrl);
    await _persist();
  }

  Future<void> removePhoto() async {
    state = state.copyWith(clearPhoto: true);
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