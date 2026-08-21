import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> createUser(
      UserModel user) async {

    await firestore
        .collection("users")
        .doc(user.uid)
        .set(user.toMap());
  }

  Future<UserModel?> getUser(
      String uid) async {

    final doc = await firestore
        .collection("users")
        .doc(uid)
        .get(const GetOptions(source: Source.serverAndCache));

    if (!doc.exists) return null;

    return UserModel.fromMap(
      doc.data()!,
    );
  }
}