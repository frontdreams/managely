import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'managely_icon_base64.dart';

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
              'html': _brandedHtml(greetName: greetName, code: code),
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

  /// Branded verification-code email — the app's monochrome black/white
  /// look (logo, black-bordered code box, system font stack) carried over
  /// into a plain-HTML email, with the icon inlined as a `data:` URI since
  /// email clients can't load a local asset path.
  String _brandedHtml({required String greetName, required String code}) {
    return '''
      <div style="background-color:#f7f7f8; padding:32px 16px; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
        <div style="max-width:420px; margin:0 auto; background-color:#ffffff; border:1px solid #e5e5e8; border-radius:16px; padding:32px 28px;">
          <img src="data:image/png;base64,$managelyIconBase64" width="40" height="38" alt="Managely" style="display:block; margin:0 0 24px;" />
          <h1 style="margin:0 0 8px; font-size:22px; font-weight:800; color:#0a0a0a;">Verify your email</h1>
          <p style="margin:0 0 24px; font-size:15px; line-height:1.5; color:#0a0a0a;">Hi $greetName, use this code to verify your Managely account:</p>
          <div style="border:1.5px solid #0a0a0a; border-radius:12px; padding:18px 12px; text-align:center; margin-bottom:24px;">
            <span style="font-size:34px; font-weight:800; letter-spacing:10px; color:#0a0a0a;">$code</span>
          </div>
          <p style="margin:0; font-size:13px; line-height:1.5; color:#6b7280;">This code expires in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
          <div style="margin-top:28px; padding-top:20px; border-top:1px solid #e5e5e8;">
            <p style="margin:0; font-size:12px; color:#9ca3af;">Managely &middot; Practice difficult conversations, without the risk.</p>
          </div>
        </div>
      </div>
    ''';
  }
}
