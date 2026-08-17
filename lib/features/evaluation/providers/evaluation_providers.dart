import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/conversation.dart';
import '../../../models/evaluation.dart';
import '../../../models/scenario.dart';
import '../../profile/providers/profile_providers.dart';
import '../../progress/providers/progress_providers.dart';

const _uuid = Uuid();

/// Call once, right when an evaluation screen first shows a result, to
/// persist the outcome into the user's skill scores and session history.
class EvaluationRecorder {
  EvaluationRecorder(this.ref);
  final Ref ref;

  Future<void> record({
    required Scenario scenario,
    required ConversationEvaluation evaluation,
  }) async {
    final sessionScores = {
      for (final s in evaluation.skillScores) s.skill: s.score,
    };

    await ref.read(userProfileProvider.notifier).recordSessionResult(sessionScores);

    await ref.read(sessionHistoryProvider.notifier).addSession(
          PracticeSession(
            id: _uuid.v4(),
            scenarioId: scenario.id,
            scenarioTitle: scenario.title,
            score: evaluation.overallScore,
            date: DateTime.now(),
            improvementFromLastAttempt: evaluation.improvement,
          ),
        );
  }
}

final evaluationRecorderProvider = Provider<EvaluationRecorder>((ref) {
  return EvaluationRecorder(ref);
});
