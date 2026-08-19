import 'message.dart';
import 'evaluation.dart';

/// Represents one full attempt at a scenario, including all chat messages
/// and (once finished) its evaluation.
class Conversation {
  final String id;
  final String scenarioId;
  final List<Message> messages;
  final DateTime startedAt;
  final DateTime? endedAt;
  final ConversationEvaluation? evaluation;
  final int roundNumber;

  const Conversation({
    required this.id,
    required this.scenarioId,
    required this.messages,
    required this.startedAt,
    this.endedAt,
    this.evaluation,
    this.roundNumber = 1,
  });

  Conversation copyWith({
    List<Message>? messages,
    DateTime? endedAt,
    ConversationEvaluation? evaluation,
  }) {
    return Conversation(
      id: id,
      scenarioId: scenarioId,
      messages: messages ?? this.messages,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      evaluation: evaluation ?? this.evaluation,
      roundNumber: roundNumber,
    );
  }
}

/// A lightweight record used on the Progress screen and Home "Continue
/// Practising" card — a completed session summary.
///
/// [skillScores], [whatYouDidWell], [opportunities] and [tryNextTime] mirror
/// the full [ConversationEvaluation] the session was scored with, so tapping
/// a past session in Progress can reopen the same completion screen shown
/// right after that conversation. They're nullable because sessions
/// recorded before this field existed won't have them.
class PracticeSession {
  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final int score;
  final DateTime date;
  final int? improvementFromLastAttempt;
  final List<SkillScore>? skillScores;
  final List<String>? whatYouDidWell;
  final List<String>? opportunities;
  final List<String>? tryNextTime;

  const PracticeSession({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.score,
    required this.date,
    this.improvementFromLastAttempt,
    this.skillScores,
    this.whatYouDidWell,
    this.opportunities,
    this.tryNextTime,
  });

  /// Reconstructs the full evaluation this session was recorded with, or
  /// null if it predates that data being stored.
  ConversationEvaluation? toEvaluation() {
    if (skillScores == null ||
        whatYouDidWell == null ||
        opportunities == null ||
        tryNextTime == null) {
      return null;
    }
    return ConversationEvaluation(
      overallScore: score,
      skillScores: skillScores!,
      whatYouDidWell: whatYouDidWell!,
      opportunities: opportunities!,
      tryNextTime: tryNextTime!,
      previousScore: improvementFromLastAttempt == null
          ? null
          : score - improvementFromLastAttempt!,
    );
  }
}
