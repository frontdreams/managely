import 'scenario.dart';

/// Result of comparing a practiced conversation against how the real
/// meeting actually went, per the user's own debrief answers.
class DebriefAnalysis {
  final String comparisonSummary;
  final ManagerSkill recommendedSkill;
  final String encouragement;

  const DebriefAnalysis({
    required this.comparisonSummary,
    required this.recommendedSkill,
    required this.encouragement,
  });
}