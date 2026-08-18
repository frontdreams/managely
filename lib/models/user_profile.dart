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
  final List<ManagerSkill> focusSkills;
  final Map<ManagerSkill, int> skillScores;
  final int totalConversations;
  final int completedScenarios;
  final int currentStreak;
  final bool onboardingComplete;
  final bool themeIsDark;
  final bool notificationsEnabled;

  /// True once this profile has been loaded from Firestore for the signed-in
  /// user (or confirmed to not exist yet, for a brand-new account). Used by
  /// routing to avoid flashing onboarding before the real profile arrives.
  final bool isHydrated;

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
    this.themeIsDark = false,
    this.notificationsEnabled = true,
    this.isHydrated = false,
  });

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
    bool? themeIsDark,
    bool? notificationsEnabled,
    bool? isHydrated,
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
      themeIsDark: themeIsDark ?? this.themeIsDark,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}
