import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/real_meeting_plan.dart';
import '../services/real_meeting_repository.dart';

final realMeetingRepositoryProvider = Provider<RealMeetingRepository>((ref) {
  return RealMeetingRepository(ref.watch(firestoreProvider));
});

/// Holds the real-meeting details the user is filling in on
/// CustomScenarioConfirmScreen, before the plan has actually been created
/// in Firestore. Set right before starting the roleplay, read on the
/// evaluation screen once practice finishes (to persist the result and
/// schedule the reminder), then cleared.
class PendingRealMeetingDraft {
  final MeetingType meetingType;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? prepNotes;

  const PendingRealMeetingDraft({
    required this.meetingType,
    required this.scheduledAt,
    required this.durationMinutes,
    this.prepNotes,
  });
}

final pendingRealMeetingProvider = StateProvider<PendingRealMeetingDraft?>((ref) => null);

/// Set by NotificationService when a debrief reminder is tapped (even from
/// a cold start). The router's redirect logic watches this the same way
/// it watches onboarding/subscription state, and navigates to the debrief
/// screen — see the `_RouterRefreshNotifier` wiring in app_router.dart.
final pendingDebriefIdProvider = StateProvider<String?>((ref) => null);

/// Meetings that happened over an hour ago with no debrief logged yet —
/// backs the Home screen's reminder banner, in case the OS notification
/// was missed, dismissed, or notifications are disabled entirely.
final dueDebriefsProvider = StreamProvider.autoDispose<List<RealMeetingPlan>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(realMeetingRepositoryProvider).watchDueDebriefs(uid);
});