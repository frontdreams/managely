import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show ThemeMode;
import '../../models/conversation.dart';
import '../../models/evaluation.dart';
import '../../models/scenario.dart';
import '../../models/user_profile.dart';

/// Reads and writes a signed-in user's profile and session history under
/// `/users/{uid}` in Firestore.
class FirestoreUserRepository {
  FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Reads the new tri-state `themeMode` field, falling back to the
  /// pre-existing boolean `themeIsDark` for accounts saved before this
  /// field existed — `true` migrates to [ThemeMode.dark], `false` or
  /// absent migrates to [ThemeMode.system] rather than [ThemeMode.light],
  /// since a user who never touched the old toggle was always just
  /// getting light by coincidence (the only mode that existed), not
  /// because they rejected dark mode.
  ThemeMode _themeModeFromJson(Map<String, dynamic> json) {
    final raw = json['themeMode'] as String?;
    if (raw != null) {
      return ThemeMode.values.firstWhere((m) => m.name == raw, orElse: () => ThemeMode.system);
    }
    return (json['themeIsDark'] as bool? ?? false) ? ThemeMode.dark : ThemeMode.system;
  }

  Future<UserProfile?> loadProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) return null;
    return _profileFromJson(snapshot.data()!);
  }

  Future<void> saveProfile(String uid, UserProfile profile) {
    return _userDoc(uid).set(_profileToJson(profile), SetOptions(merge: true));
  }

  /// Live updates to just the `subscriptionTier` field — the one field that
  /// can now change purely server-side (a renewal, cancellation, or refund
  /// verified by managely-backend from a Play/App Store notification, with
  /// no app interaction at all). Everything else about the profile is only
  /// ever changed by this device, so a narrow single-field stream avoids
  /// the churn/races of turning the whole profile into stream-driven state.
  Stream<SubscriptionTier> watchSubscriptionTier(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      final raw = snap.data()?['subscriptionTier'] as String?;
      return SubscriptionTier.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => SubscriptionTier.free,
      );
    });
  }

  /// Stores a freshly-generated email-verification code and its expiry —
  /// called right before (or when resending) the code email goes out.
  Future<void> setVerificationCode(
    String uid, {
    required String code,
    required DateTime expiresAt,
  }) {
    return _userDoc(uid).set({
      'verificationCode': code,
      'verificationCodeExpiresAt': Timestamp.fromDate(expiresAt),
    }, SetOptions(merge: true));
  }

  /// Checks [code] against the one stored for [uid]. On a match that
  /// hasn't expired, marks the account verified and clears the stored
  /// code so it can't be reused, then returns true. Returns false (without
  /// changing anything) on a wrong or expired code, so the user can retry.
  Future<bool> verifyCode(String uid, String code) async {
    final snapshot = await _userDoc(uid).get();
    final data = snapshot.data();
    if (data == null) return false;

    final storedCode = data['verificationCode'] as String?;
    final expiresAt = (data['verificationCodeExpiresAt'] as Timestamp?)?.toDate();
    if (storedCode == null || expiresAt == null) return false;
    if (storedCode != code) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;

    await _userDoc(uid).set({
      'emailVerified': true,
      'verificationCode': FieldValue.delete(),
      'verificationCodeExpiresAt': FieldValue.delete(),
    }, SetOptions(merge: true));
    return true;
  }

  Future<List<PracticeSession>> loadSessions(String uid) async {
    final snapshot = await _userDoc(uid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((d) => _sessionFromJson(d.id, d.data()))
        .toList();
  }

  Future<void> addSession(String uid, PracticeSession session) {
    return _userDoc(uid)
        .collection('sessions')
        .doc(session.id)
        .set(_sessionToJson(session));
  }

  Map<String, dynamic> _profileToJson(UserProfile p) => {
        'name': p.name,
        'photoUrl': p.photoUrl,
        'level': p.level.name,
        'subscriptionTier': p.subscriptionTier.name,
        'focusSkills': p.focusSkills.map((s) => s.name).toList(),
        'skillScores': p.skillScores.map((k, v) => MapEntry(k.name, v)),
        'totalConversations': p.totalConversations,
        'completedScenarios': p.completedScenarios,
        'currentStreak': p.currentStreak,
        'onboardingComplete': p.onboardingComplete,
        'skillsAssessmentComplete': p.skillsAssessmentComplete,
        'themeMode': p.themeMode.name,
        // Explicitly deletes the field (rather than just omitting it) when
        // cleared back to "follow the device" — a merge write would
        // otherwise leave a previously-set override in place forever.
        'languageOverride': p.languageOverride ?? FieldValue.delete(),
        'notificationsEnabled': p.notificationsEnabled,
        'emailVerified': p.emailVerified,
      };

  UserProfile _profileFromJson(Map<String, dynamic> json) {
    const defaults = UserProfile();
    return UserProfile(
      name: json['name'] as String? ?? defaults.name,
      photoUrl: json['photoUrl'] as String?,
      level: ManagerLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => defaults.level,
      ),
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (t) => t.name == json['subscriptionTier'],
        orElse: () => defaults.subscriptionTier,
      ),
      focusSkills: (json['focusSkills'] as List<dynamic>?)
              ?.map((s) =>
                  ManagerSkill.values.firstWhere((sk) => sk.name == s))
              .toList() ??
          defaults.focusSkills,
      skillScores: (json['skillScores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              ManagerSkill.values.firstWhere((s) => s.name == k),
              v as int,
            ),
          ) ??
          defaults.skillScores,
      totalConversations: json['totalConversations'] as int? ?? 0,
      completedScenarios: json['completedScenarios'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      skillsAssessmentComplete: json['skillsAssessmentComplete'] as bool? ?? false,
      themeMode: _themeModeFromJson(json),
      languageOverride: json['languageOverride'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      isHydrated: true,
      emailVerified: json['emailVerified'] as bool? ?? defaults.emailVerified,
      // Backend-only fields (see routes/organizations.js /
      // routes/purchases.js) — deliberately absent from _profileToJson so
      // a client write can never set these itself, same reasoning as
      // subscriptionTier.
      orgId: json['orgId'] as String?,
      orgName: json['orgName'] as String?,
      orgRole: OrgRole.values.firstWhere(
        (r) => r.name == json['orgRole'],
        orElse: () => defaults.orgRole,
      ),
      orgMemberStatus: OrgMemberStatus.values.firstWhere(
        (s) => s.name == json['orgMemberStatus'],
        orElse: () => defaults.orgMemberStatus,
      ),
    );
  }

  Map<String, dynamic> _sessionToJson(PracticeSession s) => {
        'scenarioId': s.scenarioId,
        'scenarioTitle': s.scenarioTitle,
        'score': s.score,
        'date': Timestamp.fromDate(s.date),
        'improvement': s.improvementFromLastAttempt,
        if (s.skillScores != null)
          'skillScores': s.skillScores!
              .map((sc) => {'skill': sc.skill.name, 'score': sc.score})
              .toList(),
        if (s.whatYouDidWell != null) 'whatYouDidWell': s.whatYouDidWell,
        if (s.opportunities != null) 'opportunities': s.opportunities,
        if (s.tryNextTime != null) 'tryNextTime': s.tryNextTime,
      };

  PracticeSession _sessionFromJson(String id, Map<String, dynamic> json) =>
      PracticeSession(
        id: id,
        scenarioId: json['scenarioId'] as String,
        scenarioTitle: json['scenarioTitle'] as String,
        score: json['score'] as int,
        date: (json['date'] as Timestamp).toDate(),
        improvementFromLastAttempt: json['improvement'] as int?,
        skillScores: (json['skillScores'] as List<dynamic>?)
            ?.map((e) => SkillScore(
                  skill: ManagerSkill.values
                      .firstWhere((s) => s.name == (e as Map)['skill']),
                  score: e['score'] as int,
                ))
            .toList(),
        whatYouDidWell:
            (json['whatYouDidWell'] as List<dynamic>?)?.cast<String>(),
        opportunities: (json['opportunities'] as List<dynamic>?)?.cast<String>(),
        tryNextTime: (json['tryNextTime'] as List<dynamic>?)?.cast<String>(),
      );
}
