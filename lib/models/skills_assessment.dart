import 'scenario.dart';

/// One answer choice in a Skills Assessment question. [score] is this
/// response's quality, 0-100 — not a "correct answer," but how strong a
/// response it is by the standards of the framework the question is
/// modeled on (see [AssessmentQuestion.frameworkNote]).
class AssessmentOption {
  final String text;
  final int score;
  const AssessmentOption({required this.text, required this.score});
}

/// A single Situational Judgment Test (SJT) item: a realistic workplace
/// scenario with several possible responses of varying quality. This is
/// the same methodology used in real leadership assessment centers (SHL,
/// Hogan-style tools) — give a realistic situation, see what the person
/// would actually do, rather than asking them to self-rate.
///
/// This is a self-built assessment, not a licensed clinical instrument —
/// see [frameworkNote] for what real-world framework each question is
/// grounded in.
class AssessmentQuestion {
  final String id;
  final ManagerSkill skill;
  final String prompt;
  final List<AssessmentOption> options;
  final String frameworkNote;

  const AssessmentQuestion({
    required this.id,
    required this.skill,
    required this.prompt,
    required this.options,
    required this.frameworkNote,
  });
}

class AssessmentResult {
  final Map<ManagerSkill, int> skillScores;
  const AssessmentResult({required this.skillScores});

  int get overallScore {
    if (skillScores.isEmpty) return 0;
    final total = skillScores.values.fold<int>(0, (a, b) => a + b);
    return (total / skillScores.length).round();
  }
}