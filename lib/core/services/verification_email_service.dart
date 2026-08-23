import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends the 6-digit email-verification code by calling
/// `managely-backend`'s `/v1/send-verification-code` route, which holds
/// the real Resend API key server-side and forwards it via Resend's SMTP
/// relay. Replaces an earlier version of this class that called Resend's
/// REST API directly from the app — that meant shipping a real, send-
/// capable Resend API key inside the compiled APK, extractable by anyone.
/// Same shared-secret auth as [RemoteAIConversationService], since this
/// hits the same backend.
class VerificationEmailService {
  VerificationEmailService({
    required this.baseUrl,
    required this.appSharedSecret,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// e.g. https://managely-backend.onrender.com (no trailing slash)
  final String baseUrl;

  /// Must match APP_SHARED_SECRET in the backend's environment.
  final String appSharedSecret;

  final http.Client _client;

  Future<void> sendVerificationCode({
    required String email,
    required String name,
    required String code,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/v1/send-verification-code'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $appSharedSecret',
            },
            body: jsonEncode({'email': email, 'name': name, 'code': code}),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Timed out sending the code. Check your connection and try again.');
    }

    if (response.statusCode != 200) {
      throw Exception('Couldn\'t send the code (${_errorMessage(response.body)}).');
    }
  }

  /// Pulls the backend's `{ "error": "..." }` out of a failed response so
  /// the real cause surfaces instead of a raw status code.
  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Not JSON — fall through.
    }
    return 'request failed';
  }
}
