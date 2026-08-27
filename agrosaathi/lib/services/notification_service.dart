import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/growth_plan_model.dart';
import '../models/notification_model.dart';
import 'firestore_refs.dart';

/// Unified NotificationService handling both local device push reminders
/// (for growth plans) and Firestore in-app notifications (for marketplace/bids/alerts).
class NotificationService {
  // ── Local Device Notifications ──────────────────────────────────────────────
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print('NotificationService.init error: $e');
    }
  }

  static Future<void> scheduleForPlan(String planId, GrowthPlan plan) async {
    final idBase = planId.hashCode.abs() % 100000;

    for (int i = 0; i < plan.irrigationSchedule.length; i++) {
      final rawDate = plan.irrigationSchedule[i]['date'];
      final date = rawDate is Timestamp
          ? rawDate.toDate()
          : (rawDate is DateTime ? rawDate : DateTime.now());

      await _schedule(
        id: idBase + i,
        title: 'Irrigation Reminder',
        body: '${plan.cropName}: time to water your crop',
        date: date,
      );
    }

    for (int i = 0; i < plan.fertilizerSchedule.length; i++) {
      final entry = plan.fertilizerSchedule[i];
      final rawDate = entry['applicationDate'];
      final date = rawDate is Timestamp
          ? rawDate.toDate()
          : (rawDate is DateTime ? rawDate : DateTime.now());

      await _schedule(
        id: idBase + 1000 + i,
        title: 'Fertilizer Reminder',
        body:
            '${plan.cropName}: apply ${entry['fertilizerType']} (${entry['stage']} stage)',
        date: date,
      );
    }

    for (int i = 0; i < plan.pestControlReminders.length; i++) {
      final entry = plan.pestControlReminders[i];
      final rawDate = entry['date'];
      final date = rawDate is Timestamp
          ? rawDate.toDate()
          : (rawDate is DateTime ? rawDate : DateTime.now());

      await _schedule(
        id: idBase + 2000 + i,
        title: 'Pest Watch',
        body: entry['message'] ?? '',
        date: date,
      );
    }
  }

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
    if (date.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(
      DateTime(date.year, date.month, date.day, 7, 0),
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
          channelDescription:
              'Irrigation, fertilizer, and pest-watch reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // ── Firestore In-App Notifications (Subcollection: users/{uid}/notifications) ──

  Stream<List<NotificationItem>> getUserNotificationItems(String userId) {
    return FirestoreRefs.notifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return FirestoreRefs.notifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<int> getUnreadCount(String userId) {
    return FirestoreRefs.notifications(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await FirestoreRefs.notifications(userId)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await FirestoreRefs.notifications(userId)
        .where('isRead', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = FirestoreRefs.firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String listingId,
  }) async {
    final notification = NotificationModel(
      title: title,
      body: body,
      listingId: listingId,
    );
    await FirestoreRefs.notifications(userId).add(notification.toMap());
  }
}
