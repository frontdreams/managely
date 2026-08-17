import 'scenario.dart';

enum ManagerLevel { newManager, developingManager, experiencedManager }

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
  final ManagerLevel level;
  final List<ManagerSkill> focusSkills;
  final Map<ManagerSkill, int> skillScores;
  final int totalConversations;
  final int completedScenarios;
  final int currentStreak;
  final bool onboardingComplete;
  final bool themeIsDark;
  final bool notificationsEnabled;

  const UserProfile({
    this.name = 'You',
    this.level = ManagerLevel.newManager,
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
    ManagerLevel? level,
    List<ManagerSkill>? focusSkills,
    Map<ManagerSkill, int>? skillScores,
    int? totalConversations,
    int? completedScenarios,
    int? currentStreak,
    bool? onboardingComplete,
    bool? themeIsDark,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      name: name ?? this.name,
      level: level ?? this.level,
      focusSkills: focusSkills ?? this.focusSkills,
      skillScores: skillScores ?? this.skillScores,
      totalConversations: totalConversations ?? this.totalConversations,
      completedScenarios: completedScenarios ?? this.completedScenarios,
      currentStreak: currentStreak ?? this.currentStreak,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      themeIsDark: themeIsDark ?? this.themeIsDark,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
