import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../models/scenario.dart';
import '../../models/message.dart';
import '../../models/evaluation.dart';
import 'ai_conversation_service.dart';
import 'scenario_json_mapper.dart';

const _uuid = Uuid();

/// Production implementation of [AIConversationService]. Calls the secure
/// Managely backend (see `/managely-backend` in the project root) instead
/// of talking to Anthropic directly — the API key never lives in this app.
///
/// Wire this in by replacing the override in `service_providers.dart`:
///
/// ```dart
final aiConversationServiceProvider = Provider<AIConversationService>((ref) {
   return RemoteAIConversationService(
     baseUrl: 'https://managely-backend.onrender.com',
     appSharedSecret: '43a7d7aed10e26ee6346d84e23253204',
   );
 });
/// ```
class RemoteAIConversationService implements AIConversationService {
  RemoteAIConversationService({
    required this.baseUrl,
    required this.appSharedSecret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// e.g. https://managely-backend.onrender.com (no trailing slash)
  final String baseUrl;

  /// Must match APP_SHARED_SECRET in the backend's environment.
  final String appSharedSecret;

  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $appSharedSecret',
      };

  @override
  Future<String> generateEmployeeResponse({
    required Scenario scenario,
    required List<Message> conversation,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/employee-reply'),
      headers: _headers,
      body: jsonEncode({
        'scenario': {
          'employeeName': scenario.employeeName,
          'employeeRole': scenario.employeeRole,
          'employeePersonality': scenario.employeePersonality,
          'situation': scenario.situation,
          'objective': scenario.objective,
        },
        'conversation': conversation
            .map((m) => {
                  'sender': m.sender == MessageSender.manager ? 'manager' : 'employee',
                  'text': m.text,
                })
            .toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('employee-reply failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['reply'] as String?)?.trim() ??
        'Sorry, could you say that again?';
  }

  @override
  Future<ConversationEvaluation> evaluateConversation({
    required Scenario scenario,
    required List<Message> conversation,
    int? previousScore,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/evaluate-conversation'),
      headers: _headers,
      body: jsonEncode({
        'scenario': {
          'employeeName': scenario.employeeName,
          'objective': scenario.objective,
        },
        'conversation': conversation
            .map((m) => {
                  'sender': m.sender == MessageSender.manager ? 'manager' : 'employee',
                  'text': m.text,
                })
            .toList(),
        'previousScore': previousScore,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('evaluate-conversation failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ScenarioJsonMapper.evaluationFromJson(body);
  }

  @override
  Future<Scenario> generateCustomScenario({required String prompt}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/custom-scenario'),
      headers: _headers,
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode != 200) {
      throw Exception('custom-scenario failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ScenarioJsonMapper.scenarioFromJson(body, id: 'custom-${_uuid.v4()}');
  }
}