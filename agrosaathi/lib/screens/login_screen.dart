import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'dashboard_screen.dart';
import 'profile_setup_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final AuthService authService = AuthService();

  String verificationId = "";
  bool otpSent = false;
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> handleLoginSuccess([String? explicitUid]) async {
    final uid = explicitUid ?? authService.currentUser?.uid;
    if (uid == null) return;

    final existingUser = await FirestoreService().getUser(uid);

    if (!mounted) return;

    if (existingUser != null) {
      UserService.currentUser = existingUser;
      LocalizationService.init();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  /// Demo bypass login for instant testing / presentation
  Future<void> _loginAsDemoFarmer() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint("Anonymous sign-in for demo mode: $e");
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_farmer_101';
    final demoUser = UserModel(
      uid: uid,
      name: 'Ramesh Patil',
      phone: '+919876543210',
      role: 'Farmer',
      preferredLanguage: 'English',
      farmDetails: {
        'farmSizeAcres': 3.5,
        'defaultSoilType': 'black',
        'defaultWaterAvailability': 'medium',
      },
    );
    UserService.currentUser = demoUser;
    LocalizationService.init();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Hero Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco_rounded, size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AgroSaathi',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Smart Agriculture & Advisory Assistant',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Login Card
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Log in with your registered phone number",
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            hintText: "+919876543210",
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (otpSent) ...[
                          TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Enter 6-Digit OTP",
                              prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        AppButton(
                          text: otpSent ? "Verify OTP" : "Send OTP",
                          isLoading: isLoading,
                          onPressed: () async {
                            if (!otpSent) {
                              if (phoneController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your phone number')),
                                );
                                return;
                              }

                              await authService.verifyPhone(
                                phoneController.text.trim(),
                                (id) {
                                  setState(() {
                                    verificationId = id;
                                    otpSent = true;
                                  });
                                },
                              );
                            } else {
                              try {
                                setState(() => isLoading = true);
                                await authService.verifyOTP(
                                  verificationId,
                                  otpController.text.trim(),
                                );
                                await handleLoginSuccess();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => isLoading = false);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Demo Testing Bypass Option Card
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Quick Presentation Access",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _loginAsDemoFarmer,
                          icon: const Icon(Icons.touch_app_rounded, size: 20),
                          label: const Text(
                            "Instant Demo Login (Ramesh Patil)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}