import 'package:flutter/material.dart';

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
  void _loginAsDemoFarmer() {
    final demoUser = UserModel(
      uid: 'demo_farmer_101',
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AgroSaathi Login"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branding Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.eco, size: 45, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'AgroSaathi',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Smart Agriculture Assistant',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Login Form Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        hintText: "+919876543210",
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (otpSent) ...[
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Enter 6-Digit OTP",
                          prefixIcon: Icon(Icons.lock_clock_outlined, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
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

              // Demo Testing Bypass Option
              OutlinedButton.icon(
                onPressed: _loginAsDemoFarmer,
                icon: const Icon(Icons.touch_app, size: 18),
                label: const Text("Instant Demo Login (Ramesh Patil)"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}