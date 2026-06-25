import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<void> verifyPhone(
    String phoneNumber,
    Function(String) codeSent,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted:
          (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(
          credential,
        );
      },

      verificationFailed:
          (FirebaseAuthException e) {
        print(e.message);
      },

      codeSent:
          (String verificationId,
              int? resendToken) {
        codeSent(verificationId);
      },

      codeAutoRetrievalTimeout:
          (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOTP(
    String verificationId,
    String otp,
  ) async {
    PhoneAuthCredential credential =
        PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    return await _auth.signInWithCredential(
      credential,
    );
  }

  User? get currentUser =>
      _auth.currentUser;

  Future<void> signOut() async {
    await _auth.signOut();
  }
}