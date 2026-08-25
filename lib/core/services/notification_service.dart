import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Wraps `flutter_local_notifications` for the one thing this app needs
/// it for: reminding a user to debrief a real meeting they practiced for,
/// one hour after it happened. Nothing else in the app should touch the
/// plugin directly — go through this class so there's one place that
/// knows the payload format and channel setup.
///
/// PLATFORM SETUP THIS ASSUMES (not code — do these once):
/// - Android: add the RECEIVE_BOOT_COMPLETED and SCHEDULE_EXACT_ALARM
///   permissions to AndroidManifest.xml if you want reminders to survive
///   a device reboot and fire at exact times respectively.
/// - iOS: notification permission is requested via [requestPermissions] —
///   call it once, e.g. right after onboarding, not on cold start (a
///   permission prompt before the user has any reason to want reminders
///   gets auto-denied far more often).
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String>.broadcast();

  /// Emits the `RealMeetingPlan.id` whenever the user taps a debrief
  /// reminder notification. The app router listens to this (via
  /// `pendingDebriefIdProvider`) to navigate to the debrief screen even
  /// from a cold start.
  Stream<String> get onDebriefNotificationTapped => _tapController.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // ask explicitly later, see requestPermissions()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapController.add(payload);
        }
      },
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (iosGranted ?? true) && (androidGranted ?? true);
  }

  /// Schedules the debrief reminder for one hour after [meetingScheduledAt].
  /// [planId] becomes the notification's id (hashed to an int, since the
  /// plugin needs a stable int) and its tap payload.
  Future<void> scheduleDebriefReminder({
    required String planId,
    required DateTime meetingScheduledAt,
    required String meetingTypeLabel,
  }) async {
    final fireAt = meetingScheduledAt.add(const Duration(hours: 1));
    if (fireAt.isBefore(DateTime.now())) return; // don't schedule in the past

    await _plugin.zonedSchedule(
      id: planId.hashCode,
      title: 'How did it go?',
      body:
          'You had a $meetingTypeLabel scheduled an hour ago — log a quick debrief while it\'s fresh.',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'debrief_reminders',
          'Post-Meeting Debriefs',
          channelDescription: 'Reminders to debrief a real meeting you practiced for',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: planId,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String planId) => _plugin.cancel(id: planId.hashCode);
}