import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/growth_plan_model.dart';

/// Schedules local reminders for irrigation, fertilizer, and pest-watch dates.
/// Call NotificationService.init() once in main.dart before runApp().
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    // Android 13+ (API 33) requires this runtime permission or notifications
    // are scheduled successfully but never actually shown.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleForPlan(String planId, GrowthPlan plan) async {
    final idBase = planId.hashCode.abs() % 100000;

    for (int i = 0; i < plan.irrigationSchedule.length; i++) {
      final date = (plan.irrigationSchedule[i]['date'] as Timestamp).toDate();
      await _schedule(
        id: idBase + i,
        title: 'Irrigation Reminder',
        body: '${plan.cropName}: time to water your crop',
        date: date,
      );
    }

    for (int i = 0; i < plan.fertilizerSchedule.length; i++) {
      final entry = plan.fertilizerSchedule[i];
      final date = (entry['applicationDate'] as Timestamp).toDate();
      await _schedule(
        id: idBase + 1000 + i,
        title: 'Fertilizer Reminder',
        body: '${plan.cropName}: apply ${entry['fertilizerType']} (${entry['stage']} stage)',
        date: date,
      );
    }

    for (int i = 0; i < plan.pestControlReminders.length; i++) {
      final entry = plan.pestControlReminders[i];
      final date = (entry['date'] as Timestamp).toDate();
      await _schedule(
        id: idBase + 2000 + i,
        title: 'Pest Watch',
        body: entry['message'],
        date: date,
      );
    }
  }

  /// Cancels every notification tied to a plan (call when a plan is
  /// completed/abandoned/deleted). Mirrors scheduleForPlan's id bands exactly
  /// instead of looping over a padded "total" count.
  static Future<void> cancelForPlan(String planId, GrowthPlan plan) async {
    final idBase = planId.hashCode.abs() % 100000;

    for (int i = 0; i < plan.irrigationSchedule.length; i++) {
      await _plugin.cancel(idBase + i);
    }
    for (int i = 0; i < plan.fertilizerSchedule.length; i++) {
      await _plugin.cancel(idBase + 1000 + i);
    }
    for (int i = 0; i < plan.pestControlReminders.length; i++) {
      await _plugin.cancel(idBase + 2000 + i);
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    if (date.isBefore(DateTime.now())) return; // don't schedule in the past

    final scheduledDate = tz.TZDateTime.from(
      DateTime(date.year, date.month, date.day, 7, 0), // 7 AM reminder
      tz.local,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'growth_plan_channel',
          'Growth Plan Reminders',
          channelDescription: 'Irrigation, fertilizer, and pest-watch reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
