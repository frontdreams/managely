import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart' show OrgRole, OrgMemberStatus;

/// An organization (company) account — see routes/organizations.js for
/// the server-side rules this mirrors. The Firestore doc id (and [domain])
/// is the company's email domain, e.g. "acme.com".
class Organization {
  final String domain;
  final String name;
  final String ownerUid;
  final String tier; // 'free' | 'professional'
  final String? seatBand; // product id of the purchased seat band, if any
  final int seatLimit; // 0 while on the free tier

  const Organization({
    required this.domain,
    required this.name,
    required this.ownerUid,
    required this.tier,
    required this.seatBand,
    required this.seatLimit,
  });

  bool get isProfessional => tier == 'professional';

  factory Organization.fromFirestore(String id, Map<String, dynamic> data) {
    return Organization(
      domain: id,
      name: data['name'] as String? ?? id,
      ownerUid: data['ownerUid'] as String? ?? '',
      tier: data['tier'] as String? ?? 'free',
      seatBand: data['seatBand'] as String?,
      seatLimit: (data['seatLimit'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One person's membership record within an [Organization] — see
/// `organizations/{domain}/members/{uid}` in routes/organizations.js.
/// Reuses [OrgRole]/[OrgMemberStatus] from user_profile.dart (the same
/// values a member's own profile mirrors onto itself) rather than a
/// second, easily-drifting copy of the same two enums.
class OrgMember {
  final String uid;
  final String name;
  final String? email;
  final OrgRole role;
  final OrgMemberStatus status;
  final DateTime? requestedAt;

  const OrgMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.requestedAt,
  });

  factory OrgMember.fromFirestore(String id, Map<String, dynamic> data) {
    return OrgMember(
      uid: id,
      name: data['name'] as String? ?? id,
      email: data['email'] as String?,
      role: data['role'] == 'owner' ? OrgRole.owner : OrgRole.member,
      status: OrgMemberStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => OrgMemberStatus.pending,
      ),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
    );
  }
}
