import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/scenario.dart';
import '../../../models/message.dart';
import '../../../models/evaluation.dart';
import '../../../core/services/service_providers.dart';

const _uuid = Uuid();

enum ConversationStatus { idle, active, evaluating, complete, error }

class ConversationState {
  final Scenario? scenario;
  final List<Message> messages;
  final bool isEmployeeTyping;
  final ConversationStatus status;
  final ConversationEvaluation? evaluation;
  final int roundNumber;
  final int? previousScore;
  final String? errorMessage;

  const ConversationState({
    this.scenario,
    this.messages = const [],
    this.isEmployeeTyping = false,
    this.status = ConversationStatus.idle,
    this.evaluation,
    this.roundNumber = 1,
    this.previousScore,
    this.errorMessage,
  });

  ConversationState copyWith({
    Scenario? scenario,
    List<Message>? messages,
    bool? isEmployeeTyping,
    ConversationStatus? status,
    ConversationEvaluation? evaluation,
    int? roundNumber,
    int? previousScore,
    String? errorMessage,
  }) {
    return ConversationState(
      scenario: scenario ?? this.scenario,
      messages: messages ?? this.messages,
      isEmployeeTyping: isEmployeeTyping ?? this.isEmployeeTyping,
      status: status ?? this.status,
      evaluation: evaluation ?? this.evaluation,
      roundNumber: roundNumber ?? this.roundNumber,
      previousScore: previousScore ?? this.previousScore,
      errorMessage: errorMessage,
    );
  }
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier(this._ref) : super(const ConversationState());

  final Ref _ref;

  void startScenario(Scenario scenario, {int? previousScore, int roundNumber = 1}) {
    final opening = Message(
      id: _uuid.v4(),
      sender: MessageSender.employee,
      text: scenario.openingMessage,
      timestamp: DateTime.now(),
    );
    state = ConversationState(
      scenario: scenario,
      messages: [opening],
      status: ConversationStatus.active,
      roundNumber: roundNumber,
      previousScore: previousScore,
    );
  }

  Future<void> sendManagerMessage(String text) async {
    if (state.scenario == null || text.trim().isEmpty) return;

    final managerMessage = Message(
      id: _uuid.v4(),
      sender: MessageSender.manager,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, managerMessage],
      isEmployeeTyping: true,
    );

    try {
      final service = _ref.read(aiConversationServiceProvider);
      final reply = await service.generateEmployeeResponse(
        scenario: state.scenario!,
        conversation: state.messages,
      );

      final employeeMessage = Message(
        id: _uuid.v4(),
        sender: MessageSender.employee,
        text: reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, employeeMessage],
        isEmployeeTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isEmployeeTyping: false,
        status: ConversationStatus.error,
        errorMessage: 'Something went wrong reaching the AI employee. Please try again.',
      );
    }
  }

  Future<void> endConversation() async {
    if (state.scenario == null) return;
    state = state.copyWith(status: ConversationStatus.evaluating);

    try {
      final service = _ref.read(aiConversationServiceProvider);
      final evaluation = await service.evaluateConversation(
        scenario: state.scenario!,
        conversation: state.messages,
        previousScore: state.previousScore,
      );
      state = state.copyWith(
        status: ConversationStatus.complete,
        evaluation: evaluation,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConversationStatus.error,
        errorMessage: 'We couldn\'t generate your evaluation. Please try again.',
      );
    }
  }

  void retrySameScenario() {
    if (state.scenario == null) return;
    startScenario(
      state.scenario!,
      previousScore: state.evaluation?.overallScore,
      roundNumber: state.roundNumber + 1,
    );
  }

  void reset() {
    state = const ConversationState();
  }
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier(ref);
});
