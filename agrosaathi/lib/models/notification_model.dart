import 'package:cloud_firestore/cloud_firestore.dart';

/// NotificationItem matching Firestore subcollection `users/{uid}/notifications`.
/// Schema fields: type, title, message, relatedId, isRead, createdAt.
class NotificationItem {
  final String id;
  final String type; // pestReminder | weatherAlert | bidReceived | bidAccepted | cropAdvisory | general
  final String title;
  final String message;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'body': message,
      if (relatedId != null) 'relatedId': relatedId,
      if (relatedId != null) 'listingId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationItem(
      id: id,
      type: map['type'] ?? 'general',
      title: map['title'] ?? '',
      message: map['message'] ?? map['body'] ?? '',
      relatedId: map['relatedId'] ?? map['listingId'],
      isRead: map['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }

  NotificationItem copyWith({
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// NotificationModel compatibility wrapper for Marketplace feature code.
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

  String get message => body;
  String get relatedId => listingId;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'message': body,
      'listingId': listingId,
      'relatedId': listingId,
      'type': 'bidReceived',
      'isRead': isRead,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '',
      listingId: map['listingId'] ?? map['relatedId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] as Timestamp : null,
    );
  }

  NotificationItem toNotificationItem() {
    return NotificationItem(
      id: id ?? '',
      type: 'bidReceived',
      title: title,
      message: body,
      relatedId: listingId,
      isRead: isRead,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }
}
