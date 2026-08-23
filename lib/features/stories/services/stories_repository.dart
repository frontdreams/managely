import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/story.dart';

/// Reads/writes the `stories` collection.
///
/// SECURITY: writing (create/delete) is enforced by Firestore security
/// rules checking the `admin` custom claim server-side — NOT by any check
/// in this class. The app's own admin-gated UI is a convenience, not the
/// real boundary. Add this to your firestore.rules:
///
/// ```
/// match /stories/{storyId} {
///   allow read: if request.auth != null;
///   allow create, update, delete: if request.auth.token.admin == true;
/// }
/// ```
class StoriesRepository {
  StoriesRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('stories');

  /// All stories, most recent first. Expiry is filtered client-side (see
  /// [Story.isActive]) rather than in the query — mixing a null-or-range
  /// check on `expiresAt` isn't a clean single Firestore query, and story
  /// volume is expected to be modest enough that fetching everything and
  /// filtering in memory is simpler and still fast.
  Stream<List<Story>> watchActiveStories() {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Story.fromFirestore(doc.id, doc.data()))
            .where((story) => story.isActive)
            .toList());
  }

  Future<void> createStory({
    required StoryCategory category,
    String? title,
    String? body,
    String? imageUrl,
    String? videoUrl,
    StoryBackground background = StoryBackground.black,
    DateTime? expiresAt,
    required String postedByUid,
    String? postedByName,
  }) async {
    await _collection.add({
      'category': category.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'background': background.name,
      'postedByUid': postedByUid,
      'postedByName': postedByName,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
    });
  }

  Future<void> deleteStory(String id) => _collection.doc(id).delete();
}