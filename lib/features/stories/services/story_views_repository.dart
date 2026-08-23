import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/story.dart';

/// Reads/writes `/story_views/{uid}` — a small, separate-from-UserProfile
/// document holding when this user last viewed each [StoryCategory].
/// Deliberately kept isolated from the main user profile document rather
/// than added as a field there, so this feature doesn't need to touch
/// profile serialization at all.
///
/// Firestore rule needed:
/// ```
/// match /story_views/{uid} {
///   allow read, write: if request.auth != null && request.auth.uid == uid;
/// }
/// ```
class StoryViewsRepository {
  StoryViewsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('story_views').doc(uid);

  Future<Map<StoryCategory, DateTime>> loadLastSeen(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    if (data == null) return {};

    final result = <StoryCategory, DateTime>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[StoryCategoryX.fromName(key)] = value.toDate();
      }
    });
    return result;
  }

  Future<void> markCategorySeen(String uid, StoryCategory category) async {
    await _doc(uid).set(
      {category.name: FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}