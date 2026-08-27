import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'login_screen.dart';

/// User Profile Screen with role, farm/vendor details editing, language preferences, and logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  void _editFarmDetails(UserModel user) {
    final farmSizeController = TextEditingController(
      text: user.farmDetails?['farmSizeAcres']?.toString() ?? '2.5',
    );
    String selectedSoil = user.farmDetails?['defaultSoilType'] ?? 'Black Cotton Soil';
    String selectedWater = user.farmDetails?['defaultWaterAvailability'] ?? 'Medium';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(LocalizationService.tr('profile_farm_details')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: farmSizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('profile_farm_size'),
                    suffixText: LocalizationService.tr('acres'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSoil,
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('profile_soil'),
                  ),
                  items: ['Black Cotton Soil', 'Red Soil', 'Loamy Soil', 'Sandy Soil']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedSoil = val;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedWater,
                  decoration: InputDecoration(
                    labelText: LocalizationService.tr('profile_water'),
                  ),
                  items: ['Low', 'Medium', 'High']
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedWater = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final acres = double.tryParse(farmSizeController.text.trim()) ?? 2.5;
                final updatedFarmDetails = {
                  'farmSizeAcres': acres,
                  'defaultSoilType': selectedSoil,
                  'defaultWaterAvailability': selectedWater,
                };
                final updatedUser = user.copyWith(farmDetails: updatedFarmDetails);
                await _userService.saveUserProfile(updatedUser);
                UserService.currentUser = updatedUser;
                if (!mounted) return;
                Navigator.pop(dialogCtx);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(LocalizationService.tr('profile_logout')),
          content: const Text('Are you sure you want to sign out of AgroSaathi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await FirebaseAuth.instance.signOut();
                UserService.currentUser = null;

                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(LocalizationService.tr('profile_logout')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, currentLang, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Profile Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'AgroSaathi User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone.isNotEmpty == true ? user!.phone : 'No Phone Number',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (user?.role ?? 'Farmer').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Farm / Vendor Details Section
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.landscape_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.tr('profile_farm_details'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: user != null ? () => _editFarmDetails(user) : null,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    LocalizationService.tr('profile_farm_size'),
                    '${user?.farmDetails?['farmSizeAcres'] ?? 2.5} ${LocalizationService.tr('acres')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    LocalizationService.tr('profile_soil'),
                    (user?.farmDetails?['defaultSoilType'] ?? 'Black Cotton Soil').toString().toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    LocalizationService.tr('profile_water'),
                    (user?.farmDetails?['defaultWaterAvailability'] ?? 'Medium').toString().toUpperCase(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Language Selector Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_outlined, size: 20, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationService.tr('profile_language'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLanguageChip('en', 'English', currentLang),
                      _buildLanguageChip('hi', 'हिन्दी', currentLang),
                      _buildLanguageChip('mr', 'मराठी', currentLang),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            AppButton(
              text: LocalizationService.tr('profile_logout'),
              icon: Icons.logout,
              type: AppButtonType.outlined,
              onPressed: _confirmLogout,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageChip(String code, String label, String currentLang) {
    final isSelected = code == currentLang;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          LocalizationService.setLocale(code);
        }
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.cardBorder,
      ),
    );
  }
}