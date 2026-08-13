/// UserModel matching the agreed Firestore schema.
/// Person B owns authentication, Person A enhances it with farm profile fields.
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // "Farmer" | "Buyer" | "Admin"
  final String preferredLanguage;
  final String? profileImageUrl;
  final String? address;
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
    this.farmDetails,
    this.vendorDetails,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'preferredLanguage': preferredLanguage,
    };
    if (profileImageUrl != null) map['profileImageUrl'] = profileImageUrl;
    if (address != null) map['address'] = address;
    if (farmDetails != null) map['farmDetails'] = farmDetails;
    if (vendorDetails != null) map['vendorDetails'] = vendorDetails;
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? '',
      role: map['role'] ?? 'Farmer',
      preferredLanguage: map['preferredLanguage'] ?? 'English',
      profileImageUrl: map['profileImageUrl'],
      address: map['address'],
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
      farmDetails: farmDetails ?? this.farmDetails,
      vendorDetails: vendorDetails ?? this.vendorDetails,
    );
  }
}