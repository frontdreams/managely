import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AdminUserSummary {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String subscriptionTier;
  final String role;
  final String? lastEventType;
  final String? lastProductId;
  final double? lastAmount;
  final String? lastCurrency;
  final int? lastPurchasedAtMs;
  final int? lastExpirationAtMs;
  final String? lastStore;

  const AdminUserSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.subscriptionTier,
    required this.role,
    this.lastEventType,
    this.lastProductId,
    this.lastAmount,
    this.lastCurrency,
    this.lastPurchasedAtMs,
    this.lastExpirationAtMs,
    this.lastStore,
  });

  DateTime? get lastPurchasedAt =>
      lastPurchasedAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastPurchasedAtMs!);

  DateTime? get lastExpirationAt =>
      lastExpirationAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastExpirationAtMs!);

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    final lastEvent = json['lastEvent'] as Map<String, dynamic>?;
    return AdminUserSummary(
      uid: json['uid'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
      role: json['role'] as String? ?? 'user',
      lastEventType: lastEvent?['type'] as String?,
      lastProductId: lastEvent?['productId'] as String?,
      lastAmount: (lastEvent?['amount'] as num?)?.toDouble(),
      lastCurrency: lastEvent?['currency'] as String?,
      lastPurchasedAtMs: (lastEvent?['purchasedAtMs'] as num?)?.toInt(),
      lastExpirationAtMs: (lastEvent?['expirationAtMs'] as num?)?.toInt(),
      lastStore: lastEvent?['store'] as String?,
    );
  }
}

class RevenuePoint {
  final DateTime date;
  final double amount;
  const RevenuePoint({required this.date, required this.amount});
}

class RevenueSummary {
  final double totalRevenue;
  final int transactionCount;
  final List<RevenuePoint> series;

  const RevenueSummary({
    required this.totalRevenue,
    required this.transactionCount,
    required this.series,
  });
}

/// Calls the backend's admin-only routes. Every call sends the current
/// user's Firebase ID token — the backend verifies it and checks the
/// unforgeable `admin` custom claim server-side (see
/// managely-backend/routes/admin.js). If the token doesn't carry that
/// claim, the backend returns 403 regardless of what this app thinks the
/// user's role is.
class AdminRepository {
  AdminRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AdminUserSummary>> fetchUsers() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load users (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final users = body['users'] as List<dynamic>;
    return users
        .map((u) => AdminUserSummary.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<RevenueSummary> fetchRevenue({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  }) async {
    final uri = Uri.parse('$baseUrl/admin/revenue').replace(queryParameters: {
      'from': from.millisecondsSinceEpoch.toString(),
      'to': to.millisecondsSinceEpoch.toString(),
      'groupBy': groupBy,
    });

    final response = await _client.get(uri, headers: await _authHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to load revenue (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final series = (body['series'] as List<dynamic>)
        .map((e) => RevenuePoint(
              date: DateTime.parse(e['date'] as String),
              amount: (e['amount'] as num).toDouble(),
            ))
        .toList();

    return RevenueSummary(
      totalRevenue: (body['totalRevenue'] as num).toDouble(),
      transactionCount: body['transactionCount'] as int,
      series: series,
    );
  }
}