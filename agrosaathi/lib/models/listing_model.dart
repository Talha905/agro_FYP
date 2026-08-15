import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String? id;
  final String farmerId;
  final String cropId;
  final String cropName;
  final double quantity;
  final String unit;
  final double expectedPricePerUnit;
  final List<String> images;
  final GeoPoint? location;
  final String? geohash;
  final String status;
  final Timestamp? createdAt;
  final Timestamp? expiresAt;

  ListingModel({
    this.id,
    required this.farmerId,
    required this.cropId,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.expectedPricePerUnit,
    this.images = const [],
    this.location,
    this.geohash,
    required this.status,
    this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cropId': cropId,
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit,
      'expectedPricePerUnit': expectedPricePerUnit,
      'images': images,
      'location': location,
      'geohash': geohash,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String docId) {
    return ListingModel(
      id: docId,
      farmerId: map['farmerId'] ?? '',
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      expectedPricePerUnit: (map['expectedPricePerUnit'] ?? 0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      location: map['location'],
      geohash: map['geohash'],
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'],
      expiresAt: map['expiresAt'],
    );
  }
}
