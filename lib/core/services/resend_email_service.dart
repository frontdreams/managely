import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends the 6-digit email-verification code by calling Resend's REST API
/// directly from the app — no backend involved, so it works even when
/// `managely-backend` is down.
///
/// This embeds a real, send-capable Resend API key in the app binary,
/// which anyone can extract from a compiled APK. [apiKey] MUST be a
/// separate, sending-only key scoped to just the verified sending domain
/// (create one at https://resend.com/api-keys with "Sending access"
/// only) — never the account's full-access key — so a leaked key can only
/// send mail as this app, not touch domains/account settings.
class ResendEmailService {
  ResendEmailService({
    required this.apiKey,
    required this.fromAddress,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;

  /// e.g. "Managely <hello@yourdomain.com>" — the address must be on a
  /// domain verified in the Resend dashboard.
  final String fromAddress;

  final http.Client _client;

  static const _endpoint = 'https://api.resend.com/emails';

  Future<void> sendVerificationCode({
    required String email,
    required String name,
    required String code,
  }) async {
    final parts = name.trim().split(RegExp(r'\s+'));
    final greetName = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'there';

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'from': fromAddress,
              'to': [email],
              'subject': '$code is your Managely verification code',
              'text':
                  'Hi $greetName, your Managely verification code is $code. It expires in 10 minutes. If you didn\'t request this, you can ignore this email.',
              'html': '''
                <div style="font-family: -apple-system, Helvetica, Arial, sans-serif; max-width: 480px; margin: 0 auto; color: #0a0a0a;">
                  <h2 style="margin-bottom: 4px;">Verify your email</h2>
                  <p>Hi $greetName, use this code to verify your Managely account:</p>
                  <div style="font-size: 32px; font-weight: 700; letter-spacing: 8px; margin: 24px 0; text-align: center;">$code</div>
                  <p style="color: #6b7280; font-size: 14px;">This code expires in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
                </div>
              ''',
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Timed out sending the code. Check your connection and try again.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Couldn\'t send the code (${_errorMessage(response.statusCode, response.body)}).');
    }
  }

  /// Pulls Resend's `{ "message": "..." }` out of a failed response so the
  /// real cause (an unverified domain, a revoked key, etc.) surfaces
  /// instead of a raw status code.
  String _errorMessage(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Not JSON — fall through to the status-based message below.
    }
    return 'error $statusCode';
  }
}
