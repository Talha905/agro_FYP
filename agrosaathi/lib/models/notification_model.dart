import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String title;
  final String body;
  final String listingId;
  final bool isRead;
  final Timestamp? createdAt;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.listingId,
    this.isRead = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'listingId': listingId,
      'isRead': isRead,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      listingId: map['listingId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'],
    );
  }
}
