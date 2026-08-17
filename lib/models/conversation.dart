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
class PracticeSession {
  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final int score;
  final DateTime date;
  final int? improvementFromLastAttempt;

  const PracticeSession({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.score,
    required this.date,
    this.improvementFromLastAttempt,
  });
}
