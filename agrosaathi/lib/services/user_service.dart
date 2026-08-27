import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static UserModel? currentUser;

  Future<void> saveUserProfile(UserModel user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
    currentUser = user;
  }
}