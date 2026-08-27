import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified UserModel matching the agreed AgroSaathi Firestore schema.
/// Combines authentication, profile info, location/geohash, farm & vendor details.
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // "farmer" | "buyer" | "admin" (or "Farmer" | "Buyer" | "Admin")
  final String preferredLanguage;
  final String? profileImageUrl;
  final String? address;
  final GeoPoint? location;
  final String? geohash;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Map<String, dynamic>? farmDetails;
  final Map<String, dynamic>? vendorDetails;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.preferredLanguage,
    this.profileImageUrl,
    this.address,
    this.location,
    this.geohash,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.farmDetails,
    this.vendorDetails,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name,
      'phone': phone,
      'phoneNumber': phone,
      'role': role,
      'preferredLanguage': preferredLanguage,
      'isActive': isActive,
    };
    if (profileImageUrl != null) map['profileImageUrl'] = profileImageUrl;
    if (address != null) map['address'] = address;
    if (location != null) map['location'] = location;
    if (geohash != null) map['geohash'] = geohash;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    if (farmDetails != null) map['farmDetails'] = farmDetails;
    if (vendorDetails != null) map['vendorDetails'] = vendorDetails;
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      uid: docId ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? '',
      role: map['role'] ?? 'farmer',
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      profileImageUrl: map['profileImageUrl'],
      address: map['address'],
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      geohash: map['geohash'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] as Timestamp : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] as Timestamp : null,
      farmDetails: map['farmDetails'] != null
          ? Map<String, dynamic>.from(map['farmDetails'])
          : null,
      vendorDetails: map['vendorDetails'] != null
          ? Map<String, dynamic>.from(map['vendorDetails'])
          : null,
    );
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? role,
    String? preferredLanguage,
    String? profileImageUrl,
    String? address,
    GeoPoint? location,
    String? geohash,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Map<String, dynamic>? farmDetails,
    Map<String, dynamic>? vendorDetails,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmDetails: farmDetails ?? this.farmDetails,
      vendorDetails: vendorDetails ?? this.vendorDetails,
    );
  }
}