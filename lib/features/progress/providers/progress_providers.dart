import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/conversation.dart';
import '../../../core/services/service_providers.dart';

/// Holds the signed-in user's list of completed [PracticeSession]s, most
/// recent first, backed by their Firestore `sessions` subcollection.
class SessionHistoryNotifier extends StateNotifier<List<PracticeSession>> {
  SessionHistoryNotifier(this._ref, this._uid) : super([]) {
    if (_uid != null) _hydrate();
  }

  final Ref _ref;
  final String? _uid;

  Future<void> _hydrate() async {
    final uid = _uid;
    if (uid == null) return;
    final sessions = await _ref.read(firestoreUserRepositoryProvider).loadSessions(uid);
    state = sessions;
  }

  Future<void> addSession(PracticeSession session) async {
    final uid = _uid;
    state = [session, ...state];
    if (uid == null) return;
    await _ref.read(firestoreUserRepositoryProvider).addSession(uid, session);
  }
}

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, List<PracticeSession>>(
        (ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  return SessionHistoryNotifier(ref, uid);
});
