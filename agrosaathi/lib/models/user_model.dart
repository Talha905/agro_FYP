class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String preferredLanguage;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.preferredLanguage,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'preferredLanguage': preferredLanguage,
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
    );
  }
}