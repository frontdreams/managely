import 'scenario.dart';

class SkillScore {
  final ManagerSkill skill;
  final int score; // 0-100

  const SkillScore({required this.skill, required this.score});
}

class ConversationEvaluation {
  final int overallScore; // 0-100
  final List<SkillScore> skillScores;
  final List<String> whatYouDidWell;
  final List<String> opportunities;
  final List<String> tryNextTime;
  final int? previousScore;

  const ConversationEvaluation({
    required this.overallScore,
    required this.skillScores,
    required this.whatYouDidWell,
    required this.opportunities,
    required this.tryNextTime,
    this.previousScore,
  });

  int? get improvement =>
      previousScore == null ? null : overallScore - previousScore!;
}
