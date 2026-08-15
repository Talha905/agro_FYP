import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'firestore_refs.dart';

class NotificationService {
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
    final snapshot = await FirestoreRefs.notifications(userId).where('isRead', isEqualTo: false).get();
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
