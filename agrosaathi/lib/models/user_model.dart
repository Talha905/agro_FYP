import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String preferredLanguage;
  final GeoPoint? location;
  final String? geohash;
  final Map<String, dynamic>? farmDetails;
  final Map<String, dynamic>? vendorDetails;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.preferredLanguage,
    this.location,
    this.geohash,
    this.farmDetails,
    this.vendorDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'preferredLanguage': preferredLanguage,
      'location': location,
      'geohash': geohash,
      'farmDetails': farmDetails,
      'vendorDetails': vendorDetails,
    };
  }

  factory UserModel.fromMap(
      Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      phone: map['phone'],
      role: map['role'],
      preferredLanguage:
          map['preferredLanguage'],
      location: map['location'],
      geohash: map['geohash'],
      farmDetails: map['farmDetails'] != null ? Map<String, dynamic>.from(map['farmDetails']) : null,
      vendorDetails: map['vendorDetails'] != null ? Map<String, dynamic>.from(map['vendorDetails']) : null,
    );
  }
}