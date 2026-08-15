import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String? id;
  final String buyerId;
  final double bidAmountPerUnit;
  final double quantity;
  final String status;
  final String? message;
  final Timestamp? createdAt;

  BidModel({
    this.id,
    required this.buyerId,
    required this.bidAmountPerUnit,
    required this.quantity,
    required this.status,
    this.message,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'bidAmountPerUnit': bidAmountPerUnit,
      'quantity': quantity,
      'status': status,
      'message': message,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory BidModel.fromMap(Map<String, dynamic> map, String docId) {
    return BidModel(
      id: docId,
      buyerId: map['buyerId'] ?? '',
      bidAmountPerUnit: (map['bidAmountPerUnit'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      message: map['message'],
      createdAt: map['createdAt'],
    );
  }
}
