import 'dart:convert';
import 'package:http/http.dart' as http;

/// Calls the Managely backend to email a 6-digit verification code the
/// Flutter app already generated and stored in Firestore — this service's
/// only job is delivery, not generation or checking.
class EmailVerificationApiService {
  EmailVerificationApiService({
    required this.baseUrl,
    required this.appSharedSecret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// e.g. https://managely-backend.onrender.com (no trailing slash)
  final String baseUrl;

  /// Must match APP_SHARED_SECRET in the backend's environment.
  final String appSharedSecret;

  final http.Client _client;

  Future<void> sendCode({
    required String email,
    required String name,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/send-verification-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $appSharedSecret',
      },
      body: jsonEncode({'email': email, 'name': name, 'code': code}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'send-verification-code failed: ${response.statusCode} ${response.body}');
    }
  }
}
