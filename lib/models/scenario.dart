import 'package:flutter/material.dart';

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
  });
}
