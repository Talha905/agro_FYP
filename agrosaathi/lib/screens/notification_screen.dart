import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/firestore_refs.dart';
import '../models/listing_model.dart';
import 'listing_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final String _uid = UserService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // Mark all as read as soon as the user opens the notification screen
    // so the badge icon realistically clears immediately
    if (_uid.isNotEmpty) {
      _notificationService.markAllAsRead(_uid);
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(_uid, notification.id!);
    }

    // Navigate to listing details
    try {
      final doc = await FirestoreRefs.listings.doc(notification.listingId).get();
      if (doc.exists && mounted) {
        final listing = ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load listing details')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications', style: TextStyle(color: Colors.red[800])));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification.isRead;

              return InkWell(
                onTap: () => _handleNotificationTap(notification),
                child: Container(
                  decoration: BoxDecoration(
                    color: isRead ? Colors.transparent : Colors.green[50],
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.grey[100] : Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: isRead ? Colors.grey[500] : Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (notification.createdAt != null)
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(notification.createdAt!.toDate()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRead ? Colors.grey[500] : Colors.green[800],
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: isRead ? Colors.grey[600] : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
