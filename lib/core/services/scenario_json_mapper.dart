import '../../models/scenario.dart';
import '../../models/evaluation.dart';

/// Converts between the backend's JSON shape and Managely's Dart models.
/// Kept separate from [RemoteAIConversationService] so the parsing logic is
/// easy to unit test and easy to update if the backend contract changes.
class ScenarioJsonMapper {
  ScenarioJsonMapper._();

  static ManagerSkill skillFromName(String name) {
    return ManagerSkill.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ManagerSkill.clarity,
    );
  }

  static SkillCategory categoryFromName(String name) {
    return SkillCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => SkillCategory.difficultConversations,
    );
  }

  static ScenarioDifficulty difficultyFromName(String name) {
    return ScenarioDifficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => ScenarioDifficulty.medium,
    );
  }

  /// Builds a [Scenario] from the `/v1/custom-scenario` response.
  ///
  /// Note: [Scenario.possibleResponses] is only used by
  /// [MockAIConversationService]'s local tone-matching. When talking to a
  /// real backend, employee replies come live from `/v1/employee-reply` on
  /// every turn instead, so this is populated with a small unused
  /// placeholder purely to satisfy the model's non-nullable field.
  static Scenario scenarioFromJson(Map<String, dynamic> json, {required String id}) {
    return Scenario(
      id: id,
      title: json['title'] as String? ?? 'Custom Scenario',
      description: json['description'] as String? ?? '',
      category: categoryFromName(json['category'] as String? ?? ''),
      difficulty: difficultyFromName(json['difficulty'] as String? ?? ''),
      primarySkill: skillFromName(json['primarySkill'] as String? ?? ''),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 6,
      skillsPractised: ((json['skillsPractised'] as List?) ?? [])
          .map((e) => skillFromName(e as String))
          .toList(),
      employeeName: json['employeeName'] as String? ?? 'Jordan',
      employeeRole: json['employeeRole'] as String? ?? 'Employee',
      employeePersonality: json['employeePersonality'] as String? ?? '',
      situation: json['situation'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      openingMessage: json['openingMessage'] as String? ?? '',
      possibleResponses: const [
        PossibleResponse(triggerTone: 'default', replies: ['Okay, go on.']),
      ],
      learningPoints:
          ((json['learningPoints'] as List?) ?? []).map((e) => e as String).toList(),
    );
  }

  static int _clampScore(num? value, int fallback) {
    if (value == null) return fallback;
    return value.toInt().clamp(0, 100).toInt();
  }

  static ConversationEvaluation evaluationFromJson(Map<String, dynamic> json) {
    final skillScoresJson = json['skillScores'] as Map<String, dynamic>? ?? {};

    final skillScores = skillScoresJson.entries
        .map((e) => SkillScore(
              skill: skillFromName(e.key),
              score: _clampScore(e.value as num?, 50),
            ))
        .toList();

    return ConversationEvaluation(
      overallScore: _clampScore(json['overallScore'] as num?, 50),
      skillScores: skillScores,
      whatYouDidWell:
          ((json['whatYouDidWell'] as List?) ?? []).map((e) => e as String).toList(),
      opportunities:
          ((json['opportunities'] as List?) ?? []).map((e) => e as String).toList(),
      tryNextTime:
          ((json['tryNextTime'] as List?) ?? []).map((e) => e as String).toList(),
      previousScore: (json['previousScore'] as num?)?.toInt(),
    );
  }
}