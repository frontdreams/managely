import '../../models/scenario.dart';
import '../../models/message.dart';
import '../../models/evaluation.dart';

/// Abstraction over "the thing that plays the employee and grades the
/// manager". The UI and providers only ever talk to this interface.
///
/// -----------------------------------------------------------------------
/// FUTURE BACKEND NOTE
/// -----------------------------------------------------------------------
/// This MVP ships with [MockAIConversationService], which simulates network
/// latency and produces deterministic-but-varied responses locally.
///
/// In production this should be swapped for an implementation that calls a
/// secure backend, e.g.:
///
///   Flutter App  --https-->  Secure Backend  --api-->  Anthropic/OpenAI/Gemini
///
/// The Flutter client must NEVER hold a raw LLM API key. A real
/// implementation would look like:
///
/// class RemoteAIConversationService implements AIConversationService {
///   final String backendBaseUrl; // e.g. https://api.managely.app
///   ...
///   Future<String> generateEmployeeResponse(...) async {
///     final res = await http.post(Uri.parse('$backendBaseUrl/v1/employee-reply'),
///         body: jsonEncode({...}));
///     return jsonDecode(res.body)['reply'];
///   }
/// }
/// -----------------------------------------------------------------------
abstract class AIConversationService {
  /// Generates the next in-character line from the AI "employee", given the
  /// scenario definition and the conversation so far.
  Future<String> generateEmployeeResponse({
    required Scenario scenario,
    required List<Message> conversation,
  });

  /// Produces a full evaluation of the MANAGER's communication once the
  /// conversation has ended. This never evaluates the employee, and never
  /// produces HR/legal/psychological conclusions.
  Future<ConversationEvaluation> evaluateConversation({
    required Scenario scenario,
    required List<Message> conversation,
    int? previousScore,
  });
}
