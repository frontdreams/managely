import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Sends a completed purchase to managely-backend for real server-side
/// verification against the Google Play Developer API (Android) or
/// Apple's App Store Server API (iOS) — see
/// managely-backend/routes/purchases.js.
///
/// The backend identifies the buyer from the caller's own Firebase ID
/// token, never from a client-supplied uid — so a tampered request can at
/// most verify a real purchase for its own rightful owner, never attach
/// someone else's purchase to your account.
class PurchaseVerificationService {
  PurchaseVerificationService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// [serverVerificationData] is `PurchaseDetails.verificationData.serverVerificationData`
  /// — the raw purchase token on Android, the signed transaction (JWS) on
  /// iOS. Returns true once the backend confirms the subscription is
  /// currently active.
  Future<bool> verifyPurchase({
    required String platform, // 'android' | 'ios'
    required String productId,
    required String serverVerificationData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in — cannot verify a purchase.');
    }
    final token = await user.getIdToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/v1/verify-purchase'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'platform': platform,
        'productId': productId,
        'purchaseToken': serverVerificationData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Purchase verification failed (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['isPremium'] == true;
  }
}
