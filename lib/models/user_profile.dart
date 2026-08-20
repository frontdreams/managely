import 'scenario.dart';

enum ManagerLevel { newManager, developingManager, experiencedManager }

enum SubscriptionTier { free, premium }

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

  final bool themeIsDark;
  final bool notificationsEnabled;

  /// True once this profile has been loaded from Firestore for the signed-in
  /// user (or confirmed to not exist yet, for a brand-new account). Used by
  /// routing to avoid flashing onboarding before the real profile arrives.
  final bool isHydrated;

  /// True once the account's email has been confirmed via the 6-digit code
  /// sent at sign-up. Defaults to true so Google sign-ins (already
  /// verified by Google) and accounts created before this field existed
  /// aren't retroactively locked out — only freshly-registered
  /// email/password accounts are seeded with this false. See
  /// [UserProfileNotifier] for where that seeding happens.
  final bool emailVerified;

  const UserProfile({
    this.name = 'You',
    this.photoUrl,
    this.level = ManagerLevel.newManager,
    this.subscriptionTier = SubscriptionTier.free,
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
    this.themeIsDark = false,
    this.notificationsEnabled = true,
    this.isHydrated = false,
    this.emailVerified = true,
  });

  /// How many practice conversations a free-tier user gets per ~30 days
  /// before hitting the upgrade prompt. Premium users are unlimited.
  static const int freeConversationLimitPerCycle = 3;

  bool get isPremiumTier => subscriptionTier == SubscriptionTier.premium;

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
    List<ManagerSkill>? focusSkills,
    Map<ManagerSkill, int>? skillScores,
    int? totalConversations,
    int? completedScenarios,
    int? currentStreak,
    bool? onboardingComplete,
    bool? skillsAssessmentComplete,
    int? freeConversationsUsedThisCycle,
    DateTime? usageCycleStart,
    bool? themeIsDark,
    bool? notificationsEnabled,
    bool? isHydrated,
    bool? emailVerified,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      level: level ?? this.level,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
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
      themeIsDark: themeIsDark ?? this.themeIsDark,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isHydrated: isHydrated ?? this.isHydrated,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}