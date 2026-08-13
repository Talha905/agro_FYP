import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController farmSizeController = TextEditingController(text: '2.5');

  String selectedRole = 'Farmer';
  String selectedLanguage = 'English';
  String selectedSoil = 'black';
  String selectedWater = 'medium';

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    farmSizeController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final uid = firebaseUser?.uid ?? 'guest_farmer';
      final phone = firebaseUser?.phoneNumber ?? '+919876543210';

      final user = UserModel(
        uid: uid,
        name: nameController.text.trim(),
        phone: phone,
        role: selectedRole,
        preferredLanguage: selectedLanguage,
        farmDetails: {
          'farmSizeAcres': double.tryParse(farmSizeController.text.trim()) ?? 2.5,
          'defaultSoilType': selectedSoil,
          'defaultWaterAvailability': selectedWater,
        },
      );

      await FirestoreService().createUser(user);
      UserService.currentUser = user;
      LocalizationService.init();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Enter your name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppDropdown<String>(
                      label: 'Role',
                      value: selectedRole,
                      isRequired: true,
                      items: const [
                        AppDropdownItem(value: 'Farmer', label: 'Farmer (शेतकरी / किसान)', icon: Icons.agriculture),
                        AppDropdownItem(value: 'Buyer', label: 'Buyer (खरेदीदार / खरीदार)', icon: Icons.store),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    AppDropdown<String>(
                      label: 'Preferred Language',
                      value: selectedLanguage,
                      isRequired: true,
                      items: const [
                        AppDropdownItem(value: 'English', label: 'English', icon: Icons.language),
                        AppDropdownItem(value: 'Hindi', label: 'हिन्दी (Hindi)', icon: Icons.language),
                        AppDropdownItem(value: 'Marathi', label: 'मराठी (Marathi)', icon: Icons.language),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (selectedRole == 'Farmer') ...[
                      AppTextField(
                        controller: farmSizeController,
                        label: 'Total Farm Size (in Acres)',
                        hint: 'e.g. 3.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 16),

                      AppDropdown<String>(
                        label: 'Default Soil Type',
                        value: selectedSoil,
                        items: const [
                          AppDropdownItem(value: 'black', label: 'Black Cotton Soil', icon: Icons.grass),
                          AppDropdownItem(value: 'alluvial', label: 'Alluvial Soil', icon: Icons.landscape),
                          AppDropdownItem(value: 'red', label: 'Red / Laterite Soil', icon: Icons.terrain),
                          AppDropdownItem(value: 'clay', label: 'Clayey Soil', icon: Icons.grain),
                          AppDropdownItem(value: 'loamy', label: 'Loamy Soil', icon: Icons.filter_vintage),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedSoil = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      AppDropdown<String>(
                        label: 'Water Source Availability',
                        value: selectedWater,
                        items: const [
                          AppDropdownItem(value: 'low', label: 'Low (Rainfed / Scarce)', icon: Icons.opacity),
                          AppDropdownItem(value: 'medium', label: 'Medium (Canal / Borewell)', icon: Icons.water_drop),
                          AppDropdownItem(value: 'high', label: 'High (Abundant / Drip)', icon: Icons.waves),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedWater = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: 'Continue to Dashboard',
                isLoading: isLoading,
                onPressed: isLoading ? null : saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}