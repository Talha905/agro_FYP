import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser != null) {
          return FutureBuilder<UserModel?>(
            future: FirestoreService().getUser(firebaseUser.uid),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting && UserService.currentUser == null) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  ),
                );
              }

              if (userSnap.hasData && userSnap.data != null) {
                UserService.currentUser = userSnap.data;
              } else if (UserService.currentUser == null) {
                UserService.currentUser = UserModel(
                  uid: firebaseUser.uid,
                  name: firebaseUser.displayName ?? 'Farmer',
                  phone: firebaseUser.phoneNumber ?? '+919876543210',
                  role: 'Farmer',
                  preferredLanguage: 'English',
                  farmDetails: {
                    'farmSizeAcres': 2.5,
                    'defaultSoilType': 'black',
                    'defaultWaterAvailability': 'medium',
                  },
                );
              }

              return const DashboardScreen();
            },
          );
        }

        if (UserService.currentUser != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
