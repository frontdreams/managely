import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../../../models/scenario.dart';
import '../../../models/user_role.dart';
import '../../../core/services/local_prefs_service.dart';
import '../../../core/services/service_providers.dart';

/// Holds the signed-in user's [UserProfile], hydrated from and persisted to
/// their Firestore document (`/users/{uid}`). Re-created whenever the signed
/// in user changes (see [userProfileProvider]).
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._ref, this._uid) : super(const UserProfile()) {
    if (_uid != null) {
      _hydrate();
    } else {
      // Signed out (or not yet signed in) — there's no Firestore doc to
      // read, but the user's last chosen theme/language should still
      // carry over onto Welcome/Login/Onboarding rather than resetting to
      // the device's system defaults. See LocalPrefsService's doc comment.
      _hydrateLocalPrefsOnly();
    }
  }

  final Ref _ref;
  final String? _uid;

  Future<void> _hydrateLocalPrefsOnly() async {
    final local = await LocalPrefsService.load();
    state = state.copyWith(
      themeMode: local.themeMode,
      languageOverride: local.languageOverride,
      clearLanguageOverride: local.languageOverride == null,
    );
  }


  Future<void> _hydrate() async {
    final uid = _uid;
    if (uid == null) return;

    final repo = _ref.read(firestoreUserRepositoryProvider);
    final loaded = await repo.loadProfile(uid);
    final authUser = _ref.read(firebaseAuthProvider).currentUser;
    final authName = authUser?.displayName;
    final authPhoto = authUser?.photoURL;

    // Admin status comes from the unforgeable Firebase custom claim, NOT
    // from a Firestore field — see the security note on UserRole. Force a
    // token refresh (the `true` argument) so a claim granted server-side
    // AFTER this device's last sign-in is picked up immediately, instead
    // of waiting for the cached ID token to naturally expire (up to an
    // hour) or requiring an explicit sign-out/sign-in.
    final idTokenResult = await authUser?.getIdTokenResult(true);
    final isAdminClaim = idTokenResult?.claims?['admin'] == true;
    final role = isAdminClaim ? UserRole.admin : UserRole.user;

    if (loaded != null) {
      var next = loaded.copyWith(role: role);
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
      // Mirror this signed-in profile's theme/language locally too, so
      // they're still there to fall back on the next time this device has
      // no signed-in user (see _hydrateLocalPrefsOnly).
      await LocalPrefsService.saveThemeMode(next.themeMode);
      await LocalPrefsService.saveLanguageOverride(next.languageOverride);
      return;
    }

    // Brand-new account: seed a fresh profile (using the auth display name
    // and, for Google sign-ins, their Google profile photo) and persist it
    // immediately so the doc exists going forward. Only email/password
    // sign-ups start unverified — Google already confirmed the address.
    final isPasswordAccount =
        authUser?.providerData.any((p) => p.providerId == 'password') ?? false;
    final seeded = UserProfile(
      name: (authName != null && authName.isNotEmpty) ? authName : 'You',
      photoUrl: (authPhoto != null && authPhoto.isNotEmpty) ? authPhoto : null,
      role: role,
      isHydrated: true,
      emailVerified: !isPasswordAccount,
    );
    state = seeded;
    await repo.saveProfile(uid, seeded);
  }

  /// Re-runs hydration — including a forced token refresh, so this is also
  /// the right thing to call right after granting/revoking someone's admin
  /// claim, instead of requiring a full sign-out/sign-in to see it reflected.
  Future<void> refresh() => _hydrate();

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    await _ref.read(firestoreUserRepositoryProvider).saveProfile(uid, state);
  }

  /// Called once [EmailVerificationScreen] confirms the entered code
  /// matches — lets the router move the user on to onboarding.
  Future<void> markEmailVerified() async {
    state = state.copyWith(emailVerified: true);
    await _persist();
  }

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

  /// Keeps [UserProfile.subscriptionTier] in sync with the actual verified
  /// entitlement status — the SOURCE OF TRUTH for whether someone is
  /// Premium, driven by two things: the purchase-stream listener in
  /// main.dart (right after managely-backend verifies a fresh
  /// purchase/restore), and `subscriptionTierStreamProvider` (a live
  /// Firestore watch picking up renewals/cancellations verified purely
  /// server-side, with no app interaction). Prefer this over calling
  /// [setSubscriptionTier] directly from UI after a purchase completes.
  ///
  /// Takes the real [SubscriptionTier] rather than a bool — an org seat-
  /// band purchase grants 'professional', not 'premium', and a bool can't
  /// tell the two apart. Collapsing to a bool here once meant an org
  /// owner's own tier got silently downgraded from 'professional' back to
  /// 'premium'/'free' right after a successful purchase.
  Future<void> syncSubscriptionFromEntitlement(SubscriptionTier tier) async {
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

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await LocalPrefsService.saveThemeMode(mode);
    await _persist();
  }

  /// Pass null to go back to following the device's own language.
  Future<void> setLanguageOverride(String? languageCode) async {
    state = state.copyWith(
      languageOverride: languageCode,
      clearLanguageOverride: languageCode == null,
    );
    await LocalPrefsService.saveLanguageOverride(languageCode);
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