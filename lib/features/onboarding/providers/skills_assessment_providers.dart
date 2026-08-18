import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/skills_assessment_questions.dart';
import '../../../models/scenario.dart';
import '../../../models/skills_assessment.dart';

/// Autodispose together, as one "assessment attempt" — leaving the screen
/// (finishing, or backing out of a retake) drops all of it, so the next
/// attempt starts from a clean slate: empty answers, index 0, and a fresh
/// shuffle rather than whatever was left over from last time.
final assessmentQuestionsProvider = Provider.autoDispose<List<AssessmentQuestion>>((ref) {
  final random = Random();
  return SkillsAssessmentQuestions.all.map((q) {
    return AssessmentQuestion(
      id: q.id,
      skill: q.skill,
      prompt: q.prompt,
      // Answer order is randomized per attempt so the "correct-ish" answer
      // isn't always in the same position — the position itself shouldn't
      // be learnable.
      options: List<AssessmentOption>.from(q.options)..shuffle(random),
      frameworkNote: q.frameworkNote,
    );
  }).toList();
});

final assessmentCurrentIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// questionId -> chosen score
class AssessmentAnswersNotifier extends StateNotifier<Map<String, int>> {
  AssessmentAnswersNotifier() : super({});

  void answer(String questionId, int score) {
    state = {...state, questionId: score};
  }

  void reset() => state = {};
}

final assessmentAnswersProvider =
    StateNotifierProvider.autoDispose<AssessmentAnswersNotifier, Map<String, int>>((ref) {
  return AssessmentAnswersNotifier();
});

/// True once every question has an answer.
final assessmentIsCompleteProvider = Provider.autoDispose<bool>((ref) {
  final questions = ref.watch(assessmentQuestionsProvider);
  final answers = ref.watch(assessmentAnswersProvider);
  return questions.every((q) => answers.containsKey(q.id));
});

/// Averages the (2) answered scores per skill into a single 0-100 starting
/// score per [ManagerSkill]. Only meaningful once
/// [assessmentIsCompleteProvider] is true.
final assessmentResultProvider = Provider.autoDispose<AssessmentResult>((ref) {
  final questions = ref.watch(assessmentQuestionsProvider);
  final answers = ref.watch(assessmentAnswersProvider);

  final scoresBySkill = <ManagerSkill, List<int>>{};
  for (final q in questions) {
    final answer = answers[q.id];
    if (answer == null) continue;
    scoresBySkill.putIfAbsent(q.skill, () => []).add(answer);
  }

  final result = <ManagerSkill, int>{};
  for (final skill in ManagerSkill.values) {
    final scores = scoresBySkill[skill];
    if (scores == null || scores.isEmpty) {
      result[skill] = 50; // neutral fallback if a skill was somehow skipped
    } else {
      result[skill] = (scores.reduce((a, b) => a + b) / scores.length).round();
    }
  }

  return AssessmentResult(skillScores: result);
});
