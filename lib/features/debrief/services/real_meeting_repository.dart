import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/real_meeting_plan.dart';

/// Reads/writes `/users/{uid}/real_meetings/{id}` — kept as a subcollection
/// under the user's own doc (not a top-level collection) so Firestore's
/// default "owner can read/write their own subtree" rule pattern applies
/// cleanly, without needing a `uid` field + query filter.
///
/// Firestore rule needed:
/// ```
/// match /users/{uid}/real_meetings/{planId} {
///   allow read, write: if request.auth != null && request.auth.uid == uid;
/// }
/// ```
class RealMeetingRepository {
  RealMeetingRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('real_meetings');

  Future<String> create(String uid, RealMeetingPlan plan) async {
    final doc = await _collection(uid).add(plan.toFirestoreCreate());
    return doc.id;
  }

  Future<void> attachPracticeResult(
    String uid,
    String planId, {
    required int practiceScore,
    required Map<String, int> practiceSkillScores,
  }) async {
    await _collection(uid).doc(planId).update({
      'practiceScore': practiceScore,
      'practiceSkillScores': practiceSkillScores,
    });
  }

  Future<void> submitDebrief(
    String uid,
    String planId, {
    required int outcomeRating,
    required String achievedObjective,
    String? whatWentWell,
    String? whatWasHarder,
    String? aiComparisonSummary,
    String? aiRecommendedSkill,
  }) async {
    await _collection(uid).doc(planId).update({
      'debriefCompleted': true,
      'debriefSubmittedAt': FieldValue.serverTimestamp(),
      'outcomeRating': outcomeRating,
      'achievedObjective': achievedObjective,
      'whatWentWell': whatWentWell,
      'whatWasHarder': whatWasHarder,
      'aiComparisonSummary': aiComparisonSummary,
      'aiRecommendedSkill': aiRecommendedSkill,
    });
  }

  Future<RealMeetingPlan?> fetch(String uid, String planId) async {
    final doc = await _collection(uid).doc(planId).get();
    if (!doc.exists) return null;
    return RealMeetingPlan.fromFirestore(doc.id, doc.data()!);
  }

  /// Plans whose meeting has passed and the debrief hasn't been done yet —
  /// drives the Home screen's pending-debrief banner as a fallback for
  /// when the scheduled notification is missed or dismissed.
  Stream<List<RealMeetingPlan>> watchDueDebriefs(String uid) {
    return _collection(uid)
        .where('debriefCompleted', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RealMeetingPlan.fromFirestore(doc.id, doc.data()))
            .where((plan) => plan.isDebriefDue)
            .toList());
  }
}