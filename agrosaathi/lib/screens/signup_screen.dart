import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final farmSizeController = TextEditingController(text: "2.5");
  final addressController = TextEditingController();

  String selectedRole = 'Farmer';
  String selectedLanguage = 'English';
  String selectedSoil = 'black';
  String verificationId = "";
  bool otpSent = false;
  bool isLoading = false;

  final AuthService authService = AuthService();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    farmSizeController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegisterSuccess() async {
    final firebaseUser = authService.currentUser;
    if (firebaseUser == null) return;

    final newUser = UserModel(
      uid: firebaseUser.uid,
      name: nameController.text.trim().isEmpty ? 'Farmer' : nameController.text.trim(),
      phone: phoneController.text.trim(),
      role: selectedRole,
      preferredLanguage: selectedLanguage,
      address: addressController.text.trim().isEmpty ? 'Maharashtra, India' : addressController.text.trim(),
      farmDetails: selectedRole == 'Farmer'
          ? {
              'farmSizeAcres': double.tryParse(farmSizeController.text.trim()) ?? 2.5,
              'defaultSoilType': selectedSoil,
              'defaultWaterAvailability': 'medium',
            }
          : null,
      vendorDetails: selectedRole == 'Buyer'
          ? {
              'businessName': '${nameController.text.trim()} Trading Co.',
              'commoditiesTraded': ['Wheat', 'Rice', 'Cotton'],
            }
          : null,
    );

    await UserService.saveUserProfile(newUser);
    UserService.currentUser = newUser;
    LocalizationService.setLocale(selectedLanguage.toLowerCase().contains('hi')
        ? 'hi'
        : selectedLanguage.toLowerCase().contains('mr')
            ? 'mr'
            : 'en');

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
      appBar: AppBar(
        title: const Text("Create AgroSaathi Account"),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Join AgroSaathi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Smart Farming, AI Planning & Direct Marketplace',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          hintText: "e.g. Ramesh Patil",
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          hintText: "+919876543210",
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                        ),
                        validator: (v) => v == null || v.trim().length < 10 ? 'Enter a valid 10-digit phone number' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text("Select Role", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('🌾 Farmer')),
                              selected: selectedRole == 'Farmer',
                              onSelected: (val) => setState(() => selectedRole = 'Farmer'),
                              selectedColor: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('🛍️ Buyer / Trader')),
                              selected: selectedRole == 'Buyer',
                              onSelected: (val) => setState(() => selectedRole = 'Buyer'),
                              selectedColor: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (selectedRole == 'Farmer') ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: farmSizeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Farm Size (Acres)",
                                  prefixIcon: Icon(Icons.landscape_outlined, color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: selectedSoil,
                                decoration: const InputDecoration(labelText: "Soil Type"),
                                items: const [
                                  DropdownMenuItem(value: 'black', child: Text('Black Soil')),
                                  DropdownMenuItem(value: 'red', child: Text('Red Soil')),
                                  DropdownMenuItem(value: 'loamy', child: Text('Loamy Soil')),
                                  DropdownMenuItem(value: 'sandy', child: Text('Sandy Soil')),
                                ],
                                onChanged: (val) => setState(() => selectedSoil = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      DropdownButtonFormField<String>(
                        value: selectedLanguage,
                        decoration: const InputDecoration(
                          labelText: "Preferred Language",
                          prefixIcon: Icon(Icons.language, color: AppColors.primary),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'English', child: Text('English')),
                          DropdownMenuItem(value: 'Hindi', child: Text('हिंदी (Hindi)')),
                          DropdownMenuItem(value: 'Marathi', child: Text('मराठी (Marathi)')),
                        ],
                        onChanged: (val) => setState(() => selectedLanguage = val!),
                      ),
                      const SizedBox(height: 16),

                      if (otpSent) ...[
                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Enter 6-Digit OTP",
                            prefixIcon: Icon(Icons.lock_clock_outlined, color: AppColors.primary),
                          ),
                          validator: (v) => v == null || v.trim().length < 6 ? 'Enter 6-digit OTP' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      AppButton(
                        text: otpSent ? "Complete Registration" : "Send Verification OTP",
                        isLoading: isLoading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          if (!otpSent) {
                            setState(() => isLoading = true);
                            await authService.verifyPhone(
                              phoneController.text.trim(),
                              (id) {
                                setState(() {
                                  verificationId = id;
                                  otpSent = true;
                                  isLoading = false;
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
                              await _handleRegisterSuccess();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?", style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
