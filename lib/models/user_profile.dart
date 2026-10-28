import 'package:flutter/material.dart' show ThemeMode;
import 'scenario.dart';
import 'user_role.dart';

enum ManagerLevel { newManager, developingManager, experiencedManager }

/// `professional` is functionally identical to `premium` everywhere this is
/// checked (see [UserProfile.isPremiumTier]) — it exists as a separate
/// value only so the UI can show "Professional" instead of "Premium" for
/// members of a paying organization, per the org account model (see
/// [UserProfile.orgId]).
enum SubscriptionTier { free, premium, professional }

/// This account's relationship to an organization — none for a regular
/// individual account. See [UserProfile.orgId].
enum OrgRole { none, owner, member }

/// Only meaningful when [UserProfile.orgRole] isn't [OrgRole.none]. A
/// member's [SubscriptionTier] only actually reflects the org's paid plan
/// once they're `approved` — see routes/organizations.js's approve/remove
/// routes, the only things allowed to change this (same
/// client-can't-grant-itself-access rule as subscriptionTier itself).
enum OrgMemberStatus { none, pending, approved, removed }

extension ManagerLevelX on ManagerLevel {
  String get label {
    switch (this) {
      case ManagerLevel.newManager:
        return 'New Manager';
      case ManagerLevel.developingManager:
        return 'Developing Manager';
      case ManagerLevel.experiencedManager:
        return 'Experienced Manager';
    }
  }
}

class UserProfile {
  final String name;

  /// Either an `http(s)` URL (copied from a Google account's photo) or a
  /// raw base64-encoded JPEG (picked and uploaded by the user). Null means
  /// no photo has been set, and the UI falls back to the user's initial.
  final String? photoUrl;

  final ManagerLevel level;
  final SubscriptionTier subscriptionTier;

  /// Display-only mirror of the user's actual permission level — see the
  /// security note on [UserRole] for why this is never trusted for
  /// anything that protects data.
  final UserRole role;

  /// The user's six skills, ranked from most to least important to them —
  /// index 0 is what they most want to improve. Set once during onboarding
  /// (see `OnboardingScreen`'s drag-to-rank step) and editable later from
  /// Settings. This drives which scenarios get recommended; it does NOT
  /// hold scores — see [skillScores] for that.
  final List<ManagerSkill> focusSkills;

  /// Each skill's current 0-100 score. Starts at the baseline the user's
  /// Skills Assessment produced (see [skillsAssessmentComplete]) rather
  /// than a guess, then drifts as they complete practice conversations.
  final Map<ManagerSkill, int> skillScores;

  final int totalConversations;
  final int completedScenarios;
  final int currentStreak;
  final bool onboardingComplete;

  /// True once the user has completed the baseline Skills Assessment (the
  /// situational-judgment quiz taken right after onboarding) and
  /// [skillScores] reflects real answers rather than the neutral defaults
  /// below. Routing keeps a user on the assessment until this is true —
  /// nobody should reach an AI roleplay with only guessed starting scores.
  final bool skillsAssessmentComplete;

  /// How many practice conversations a free-tier user has STARTED in the
  /// current usage cycle (not completed — starting one counts even if
  /// they abandon it, so the cap can't be gamed by retrying). Ignored for
  /// premium users. Resets automatically once [usageCycleStart] is more
  /// than 30 days old — see [UserProfileNotifier.recordConversationStarted].
  final int freeConversationsUsedThisCycle;

  /// When the current free-tier usage cycle started. Null until the first
  /// conversation is started.
  final DateTime? usageCycleStart;

  /// Defaults to [ThemeMode.system] — so a brand-new or signed-out account
  /// (Welcome/Onboarding/auth screens, before any profile has loaded)
  /// still follows the device's own light/dark setting instead of being
  /// stuck on light. Explicit Light/Dark is a deliberate override set from
  /// the Preferences screen; see [UserProfileNotifier.setThemeMode].
  final ThemeMode themeMode;

  /// Null means "follow the device's language" (Turkish if the device is
  /// set to Turkish, English otherwise — see the locale resolution in
  /// main.dart). Set to an explicit language code ('en'/'tr') once the
  /// user picks one from the Preferences screen.
  final String? languageOverride;

  final bool notificationsEnabled;

  /// True once this profile has been loaded from Firestore for the signed-in
  /// user (or confirmed to not exist yet, for a brand-new account). Used by
  /// routing to avoid flashing onboarding before the real profile arrives.
  final bool isHydrated;
  final bool emailVerified;

  /// The company email domain this account belongs to (e.g. "acme.com"),
  /// or null for a regular individual account — also the Firestore doc id
  /// under `organizations/`. See [OrgRole] / [OrgMemberStatus].
  final String? orgId;
  final String? orgName;
  final OrgRole orgRole;
  final OrgMemberStatus orgMemberStatus;

  const UserProfile({
    this.name = 'You',
    this.photoUrl,
    this.level = ManagerLevel.newManager,
    this.subscriptionTier = SubscriptionTier.free,
    this.role = UserRole.user,
    this.focusSkills = const [],
    this.skillScores = const {
      ManagerSkill.empathy: 60,
      ManagerSkill.clarity: 55,
      ManagerSkill.assertiveness: 50,
      ManagerSkill.activeListening: 58,
      ManagerSkill.conflictManagement: 52,
      ManagerSkill.boundarySetting: 48,
    },
    this.totalConversations = 0,
    this.completedScenarios = 0,
    this.currentStreak = 0,
    this.onboardingComplete = false,
    this.skillsAssessmentComplete = false,
    this.freeConversationsUsedThisCycle = 0,
    this.usageCycleStart,
    this.themeMode = ThemeMode.system,
    this.languageOverride,
    this.notificationsEnabled = true,
    this.isHydrated = false,
    this.emailVerified = false,
    this.orgId,
    this.orgName,
    this.orgRole = OrgRole.none,
    this.orgMemberStatus = OrgMemberStatus.none,
  });

  /// How many practice conversations a free-tier user gets per ~30 days
  /// before hitting the upgrade prompt. Premium users are unlimited.
  static const int freeConversationLimitPerCycle = 3;

  bool get isPremiumTier =>
      subscriptionTier == SubscriptionTier.premium ||
      subscriptionTier == SubscriptionTier.professional;

  bool get isOrgOwner => orgRole == OrgRole.owner;
  bool get isOrgMember => orgId != null;

  /// Display-only convenience — see the security note on [UserRole].
  /// Never gate a backend call or a Firestore read purely on this; it's
  /// only safe for deciding whether to SHOW an admin nav item.
  bool get isAdmin => role == UserRole.admin;

  /// True once a free-tier user has used up their conversations for the
  /// current cycle. Always false for premium — see [isPremiumTier].
  bool get hasReachedFreeConversationLimit =>
      !isPremiumTier && freeConversationsUsedThisCycle >= freeConversationLimitPerCycle;

  int get averageScore {
    if (skillScores.isEmpty) return 0;
    final total = skillScores.values.fold<int>(0, (a, b) => a + b);
    return (total / skillScores.length).round();
  }

  ManagerSkill get weakestSkill {
    final sorted = skillScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    bool clearPhoto = false,
    ManagerLevel? level,
    SubscriptionTier? subscriptionTier,
    UserRole? role,
    List<ManagerSkill>? focusSkills,
    Map<ManagerSkill, int>? skillScores,
    int? totalConversations,
    int? completedScenarios,
    int? currentStreak,
    bool? onboardingComplete,
    bool? skillsAssessmentComplete,
    int? freeConversationsUsedThisCycle,
    DateTime? usageCycleStart,
    ThemeMode? themeMode,
    String? languageOverride,
    bool clearLanguageOverride = false,
    bool? notificationsEnabled,
    bool? isHydrated,
    bool? emailVerified,
    String? orgId,
    String? orgName,
    OrgRole? orgRole,
    OrgMemberStatus? orgMemberStatus,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      level: level ?? this.level,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      role: role ?? this.role,
      focusSkills: focusSkills ?? this.focusSkills,
      skillScores: skillScores ?? this.skillScores,
      totalConversations: totalConversations ?? this.totalConversations,
      completedScenarios: completedScenarios ?? this.completedScenarios,
      currentStreak: currentStreak ?? this.currentStreak,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      skillsAssessmentComplete:
          skillsAssessmentComplete ?? this.skillsAssessmentComplete,
      freeConversationsUsedThisCycle:
          freeConversationsUsedThisCycle ?? this.freeConversationsUsedThisCycle,
      usageCycleStart: usageCycleStart ?? this.usageCycleStart,
      themeMode: themeMode ?? this.themeMode,
      languageOverride:
          clearLanguageOverride ? null : (languageOverride ?? this.languageOverride),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isHydrated: isHydrated ?? this.isHydrated,
      emailVerified: emailVerified ?? this.emailVerified,
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      orgRole: orgRole ?? this.orgRole,
      orgMemberStatus: orgMemberStatus ?? this.orgMemberStatus,
    );
  }
}