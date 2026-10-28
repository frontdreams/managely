import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// The broad skill category a scenario primarily trains.
enum SkillCategory {
  feedback,
  boundaries,
  conflict,
  sayingNo,
  performance,
  difficultConversations,
}

extension SkillCategoryX on SkillCategory {
  /// English-only — kept for non-UI uses (logging, debug output). Any
  /// widget showing this to the user should use [labelFor] instead.
  String get label {
    switch (this) {
      case SkillCategory.feedback:
        return 'Feedback';
      case SkillCategory.boundaries:
        return 'Boundaries';
      case SkillCategory.conflict:
        return 'Conflict';
      case SkillCategory.sayingNo:
        return 'Saying No';
      case SkillCategory.performance:
        return 'Performance';
      case SkillCategory.difficultConversations:
        return 'Difficult Conversations';
    }
  }

  String labelFor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SkillCategory.feedback:
        return l10n.categoryFeedback;
      case SkillCategory.boundaries:
        return l10n.categoryBoundaries;
      case SkillCategory.conflict:
        return l10n.categoryConflict;
      case SkillCategory.sayingNo:
        return l10n.categorySayingNo;
      case SkillCategory.performance:
        return l10n.categoryPerformance;
      case SkillCategory.difficultConversations:
        return l10n.categoryDifficultConversations;
    }
  }

  IconData get icon {
    switch (this) {
      case SkillCategory.feedback:
        return Icons.forum_outlined;
      case SkillCategory.boundaries:
        return Icons.shield_outlined;
      case SkillCategory.conflict:
        return Icons.balance_outlined;
      case SkillCategory.sayingNo:
        return Icons.block_outlined;
      case SkillCategory.performance:
        return Icons.trending_up_outlined;
      case SkillCategory.difficultConversations:
        return Icons.chat_bubble_outline;
    }
  }
}

/// The specific interpersonal skill measured by the evaluation engine.
enum ManagerSkill {
  empathy,
  clarity,
  assertiveness,
  activeListening,
  conflictManagement,
  boundarySetting,
}

extension ManagerSkillX on ManagerSkill {
  /// English-only — kept for non-UI uses (logging, debug output). Any
  /// widget showing this to the user should use [labelFor] instead.
  String get label {
    switch (this) {
      case ManagerSkill.empathy:
        return 'Empathy';
      case ManagerSkill.clarity:
        return 'Clarity';
      case ManagerSkill.assertiveness:
        return 'Assertiveness';
      case ManagerSkill.activeListening:
        return 'Active Listening';
      case ManagerSkill.conflictManagement:
        return 'Conflict Management';
      case ManagerSkill.boundarySetting:
        return 'Boundary Setting';
    }
  }

  String labelFor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ManagerSkill.empathy:
        return l10n.skillEmpathy;
      case ManagerSkill.clarity:
        return l10n.skillClarity;
      case ManagerSkill.assertiveness:
        return l10n.skillAssertiveness;
      case ManagerSkill.activeListening:
        return l10n.skillActiveListening;
      case ManagerSkill.conflictManagement:
        return l10n.skillConflictManagement;
      case ManagerSkill.boundarySetting:
        return l10n.skillBoundarySetting;
    }
  }

  IconData get icon {
    switch (this) {
      case ManagerSkill.empathy:
        return Icons.favorite_border;
      case ManagerSkill.clarity:
        return Icons.lightbulb_outline;
      case ManagerSkill.assertiveness:
        return Icons.record_voice_over_outlined;
      case ManagerSkill.activeListening:
        return Icons.hearing_outlined;
      case ManagerSkill.conflictManagement:
        return Icons.handshake_outlined;
      case ManagerSkill.boundarySetting:
        return Icons.fence_outlined;
    }
  }
}

enum ScenarioDifficulty { easy, medium, hard }

extension ScenarioDifficultyX on ScenarioDifficulty {
  int get stars {
    switch (this) {
      case ScenarioDifficulty.easy:
        return 2;
      case ScenarioDifficulty.medium:
        return 3;
      case ScenarioDifficulty.hard:
        return 5;
    }
  }

  /// English-only — kept for non-UI uses (logging, debug output). Any
  /// widget showing this to the user should use [labelFor] instead.
  String get label {
    switch (this) {
      case ScenarioDifficulty.easy:
        return 'Easy';
      case ScenarioDifficulty.medium:
        return 'Medium';
      case ScenarioDifficulty.hard:
        return 'Hard';
    }
  }

  String labelFor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ScenarioDifficulty.easy:
        return l10n.difficultyEasy;
      case ScenarioDifficulty.medium:
        return l10n.difficultyMedium;
      case ScenarioDifficulty.hard:
        return l10n.difficultyHard;
    }
  }
}

/// A single canned reaction the mock AI can choose based on the tone
/// detected in the manager's most recent message.
class PossibleResponse {
  final String triggerTone; // e.g. "empathetic", "aggressive", "vague", "clear", "default"
  final List<String> replies;

  const PossibleResponse({required this.triggerTone, required this.replies});
}

class Scenario {
  final String id;
  final String title;
  final String description;
  final SkillCategory category;
  final ScenarioDifficulty difficulty;
  final ManagerSkill primarySkill;
  final int estimatedMinutes;
  final List<ManagerSkill> skillsPractised;

  final String employeeName;
  final String employeeRole;
  final String employeePersonality;
  final String situation;
  final String objective;

  final String openingMessage;
  final List<PossibleResponse> possibleResponses;
  final List<String> learningPoints;

  /// True for scenarios gated behind the Premium tier — see
  /// `UserProfile.isPremiumTier`. Defaults to false so every existing
  /// Scenario(...) literal keeps compiling without listing this field.
  final bool isPremium;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.primarySkill,
    required this.estimatedMinutes,
    required this.skillsPractised,
    required this.employeeName,
    required this.employeeRole,
    required this.employeePersonality,
    required this.situation,
    required this.objective,
    required this.openingMessage,
    required this.possibleResponses,
    required this.learningPoints,
    this.isPremium = false,
  });

  /// Generic dialogue tree used when a Firestore scenario doc doesn't have
  /// its own `possibleResponses` — e.g. one created from managelyweb's
  /// admin dashboard, which doesn't have a UI for authoring per-tone
  /// replies. Keeps [MockAIConversationService]'s offline tone-matching
  /// working for every scenario, curated or not.
  static const List<PossibleResponse> _defaultPossibleResponses = [
    PossibleResponse(triggerTone: 'empathetic', replies: [
      'I appreciate you saying that.',
      'Thanks for putting it that way.',
    ]),
    PossibleResponse(triggerTone: 'aggressive', replies: [
      "I don't think that tone is necessary.",
      'Okay, that feels a bit harsh.',
    ]),
    PossibleResponse(triggerTone: 'vague', replies: [
      "I'm still not totally clear on what you mean.",
      'Okay... but what would that look like?',
    ]),
    PossibleResponse(triggerTone: 'clear', replies: [
      "Okay, that's clear — I can work with that.",
      'Got it, thanks for being direct.',
    ]),
    PossibleResponse(triggerTone: 'default', replies: [
      "Okay, I'm listening — go on.",
      'Alright, tell me more.',
    ]),
  ];

  /// Builds a [Scenario] from a `scenarios/{id}` Firestore document — the
  /// same shape managely-backend's `POST /admin/scenarios` writes.
  factory Scenario.fromFirestore(String id, Map<String, dynamic> data) {
    SkillCategory category = SkillCategory.values.firstWhere(
      (c) => c.name == data['category'],
      orElse: () => SkillCategory.difficultConversations,
    );
    ScenarioDifficulty difficulty = ScenarioDifficulty.values.firstWhere(
      (d) => d.name == data['difficulty'],
      orElse: () => ScenarioDifficulty.medium,
    );
    ManagerSkill primarySkill = ManagerSkill.values.firstWhere(
      (s) => s.name == data['primarySkill'],
      orElse: () => ManagerSkill.clarity,
    );
    final skillsPractised = ((data['skillsPractised'] as List?) ?? [])
        .map((name) => ManagerSkill.values.firstWhere(
              (s) => s.name == name,
              orElse: () => ManagerSkill.clarity,
            ))
        .toList();
    final possibleResponses = ((data['possibleResponses'] as List?) ?? [])
        .map((r) => PossibleResponse(
              triggerTone: (r as Map)['triggerTone'] as String? ?? 'default',
              replies: ((r['replies'] as List?) ?? []).cast<String>(),
            ))
        .toList();

    return Scenario(
      id: id,
      title: data['title'] as String? ?? 'Untitled Scenario',
      description: data['description'] as String? ?? '',
      category: category,
      difficulty: difficulty,
      primarySkill: primarySkill,
      estimatedMinutes: (data['estimatedMinutes'] as num?)?.toInt() ?? 6,
      skillsPractised:
          skillsPractised.isNotEmpty ? skillsPractised : [primarySkill],
      employeeName: data['employeeName'] as String? ?? 'Jordan',
      employeeRole: data['employeeRole'] as String? ?? 'Employee',
      employeePersonality: data['employeePersonality'] as String? ?? '',
      situation: data['situation'] as String? ?? '',
      objective: data['objective'] as String? ?? '',
      openingMessage: data['openingMessage'] as String? ?? '',
      possibleResponses: possibleResponses.isNotEmpty
          ? possibleResponses
          : _defaultPossibleResponses,
      learningPoints:
          ((data['learningPoints'] as List?) ?? []).cast<String>(),
      isPremium: data['isPremium'] as bool? ?? false,
    );
  }
}