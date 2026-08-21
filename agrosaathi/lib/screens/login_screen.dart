import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

import 'dashboard_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final phoneController =
      TextEditingController();

  final otpController =
      TextEditingController();

  final AuthService authService =
      AuthService();

  String verificationId = "";

  bool otpSent = false;

  bool isLoading = false;

  Future<void> handleLoginSuccess() async {

    final firebaseUser =
        authService.currentUser;

    if (firebaseUser == null) return;

    final existingUser =
        await FirestoreService()
            .getUser(firebaseUser.uid);

    if (!mounted) return;

    if (existingUser != null) {

      UserService.currentUser =
          existingUser;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DashboardScreen(),
        ),
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileSetupScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AgroSaathi Login",
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller:
                  phoneController,

              keyboardType:
                  TextInputType.phone,

              decoration:
                  const InputDecoration(
                labelText:
                    "Phone Number",
                hintText:
                    "+919876543210",
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            if (otpSent)

              TextField(
                controller:
                    otpController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText: "OTP",
                ),
              ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: isLoading
                    ? null
                    : () async {

                        if (!otpSent) {

                          await authService
                              .verifyPhone(
                            phoneController.text,

                            (id) {
                              setState(() {
                                verificationId =
                                    id;
                                otpSent = true;
                              });
                            },
                          );

                        } else {

                          try {

                            setState(() {
                              isLoading = true;
                            });

                            await authService
                                .verifyOTP(
                              verificationId,
                              otpController.text,
                            ).timeout(const Duration(seconds: 15), onTimeout: () => throw Exception("OTP verification timed out"));

                            await handleLoginSuccess().timeout(const Duration(seconds: 15), onTimeout: () => throw Exception("Firestore connection timed out"));

                          } catch (e) {

                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              SnackBar(
                                content:
                                    Text(
                                  e.toString(),
                                ),
                              ),
                            );

                          } finally {

                            if (mounted) {

                              setState(() {
                                isLoading =
                                    false;
                              });
                            }
                          }
                        }
                      },

                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        otpSent
                            ? "Verify OTP"
                            : "Send OTP",
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // DEV BYPASS BUTTON
            TextButton(
              onPressed: () {
                // Hardcode a dummy user so we can bypass Firebase Auth
                UserService.currentUser = UserModel(
                  uid: 'dev-user-123',
                  name: 'Dev User',
                  phone: '+919518563596',
                  role: 'farmer',
                  preferredLanguage: 'en',
                );
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              child: const Text("Bypass Login (Dev Mode)", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}