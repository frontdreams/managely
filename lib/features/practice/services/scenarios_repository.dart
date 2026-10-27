import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/scenario.dart';

/// Reads the `scenarios` collection — the practice library, managed from
/// managelyweb's admin dashboard (via managely-backend's `/admin/scenarios`
/// routes) the same way Stories are.
///
/// SECURITY: writing is enforced by Firestore security rules checking the
/// `admin` custom claim server-side (see firestore.rules) — the app itself
/// never writes to this collection.
class ScenariosRepository {
  ScenariosRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('scenarios');

  /// All scenarios, ordered by title. Empty until the collection is seeded
  /// (see managely-backend/scripts/seed-scenarios.js) — callers should fall
  /// back to the bundled mock library when this stream hasn't produced a
  /// non-empty list yet, so the practice screen never renders empty.
  Stream<List<Scenario>> watchAll() {
    return _collection.orderBy('title').snapshots().map((snap) => snap.docs
        .map((doc) => Scenario.fromFirestore(doc.id, doc.data()))
        .toList());
  }
}
