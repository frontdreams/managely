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
/// was missed, dismissed, or notifications are disabled entirely. These
/// are also the "unread" notifications in the bell icon/Notifications
/// screen — see [unreadNotificationsCountProvider].
final dueDebriefsProvider = StreamProvider.autoDispose<List<RealMeetingPlan>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(realMeetingRepositoryProvider).watchDueDebriefs(uid);
});

/// Backs the Notifications screen — every meeting whose debrief window has
/// opened, whether already logged (read) or still pending (unread, i.e.
/// in [dueDebriefsProvider] too).
final debriefNotificationsProvider = StreamProvider.autoDispose<List<RealMeetingPlan>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(realMeetingRepositoryProvider).watchNotifications(uid);
});

/// Unread count for the bell icon's badge.
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(dueDebriefsProvider).valueOrNull?.length ?? 0;
});