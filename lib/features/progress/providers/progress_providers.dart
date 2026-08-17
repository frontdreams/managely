import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/conversation.dart';
import '../../../core/services/service_providers.dart';

/// Holds the list of completed [PracticeSession]s, most recent first.
class SessionHistoryNotifier extends StateNotifier<List<PracticeSession>> {
  SessionHistoryNotifier(this._ref) : super([]) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final storage = _ref.read(localStorageServiceProvider);
    final sessions = await storage.loadSessions();
    state = sessions.reversed.toList();
  }

  Future<void> addSession(PracticeSession session) async {
    final storage = _ref.read(localStorageServiceProvider);
    final updated = [session, ...state];
    state = updated;
    await storage.saveSessions(updated.reversed.toList());
  }
}

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, List<PracticeSession>>(
        (ref) {
  return SessionHistoryNotifier(ref);
});
