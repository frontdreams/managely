import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../models/organization.dart';

/// Calls managely-backend's organization routes (routes/organizations.js)
/// and watches the Firestore `organizations/{domain}` doc + its `members`
/// subcollection directly (read-only — see firestore.rules: writes are
/// backend-only, the same split already used for purchases).
class OrganizationRepository {
  OrganizationRepository({
    required this.baseUrl,
    required FirebaseFirestore firestore,
    http.Client? client,
  })  : _firestore = firestore,
        _client = client ?? http.Client();

  final String baseUrl;
  final FirebaseFirestore _firestore;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Creates a new organization for the caller's email domain, or — if
  /// one already exists for that domain — files them as a pending member
  /// of it. Called once, right after Firebase Auth account creation, from
  /// the organization sign-up screen.
  Future<({String domain, String orgName, String role, String status})> createOrJoin({
    required String companyName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/organizations'),
      headers: await _authHeaders(),
      body: jsonEncode({'companyName': companyName}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorFrom(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      domain: body['domain'] as String,
      orgName: body['orgName'] as String,
      role: body['role'] as String,
      status: body['status'] as String,
    );
  }

  Future<void> approveMember({required String domain, required String uid}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/organizations/$domain/members/$uid/approve'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_errorFrom(response));
  }

  Future<void> removeMember({required String domain, required String uid}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/organizations/$domain/members/$uid/remove'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_errorFrom(response));
  }

  String _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }

  Stream<Organization?> watchOrganization(String domain) {
    return _firestore.collection('organizations').doc(domain).snapshots().map(
          (d) => d.exists ? Organization.fromFirestore(d.id, d.data()!) : null,
        );
  }

  /// Newest request first — so a pending signup shows at the top for the
  /// admin to triage.
  Stream<List<OrgMember>> watchMembers(String domain) {
    return _firestore
        .collection('organizations')
        .doc(domain)
        .collection('members')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrgMember.fromFirestore(d.id, d.data())).toList());
  }
}
