import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/firestore_refs.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import 'login_screen.dart';

/// Complete Profile & Settings Screen.
/// Owned by Person A. Multi-language reactive.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editFarmDetails(UserModel user) {
    final farmSizeController = TextEditingController(
      text: user.farmDetails?['farmSizeAcres']?.toString() ?? '2.0',
    );
    String selectedSoil = user.farmDetails?['defaultSoilType']?.toString() ?? 'black';
    String selectedWater = user.farmDetails?['defaultWaterAvailability']?.toString() ?? 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.tr('edit_farm_details'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: LocalizationService.tr('profile_farm_size'),
                    hint: 'e.g. 3.5',
                    controller: farmSizeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: LocalizationService.tr('profile_soil'),
                    value: selectedSoil,
                    items: [
                      AppDropdownItem(value: 'black', label: LocalizationService.tr('soil_black')),
                      AppDropdownItem(value: 'alluvial', label: LocalizationService.tr('soil_alluvial')),
                      AppDropdownItem(value: 'red', label: LocalizationService.tr('soil_red')),
                      AppDropdownItem(value: 'clay', label: LocalizationService.tr('soil_clay')),
                      AppDropdownItem(value: 'loamy', label: LocalizationService.tr('soil_loamy')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSoil = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: LocalizationService.tr('profile_water'),
                    value: selectedWater,
                    items: [
                      AppDropdownItem(value: 'low', label: LocalizationService.tr('water_low')),
                      AppDropdownItem(value: 'medium', label: LocalizationService.tr('water_medium')),
                      AppDropdownItem(value: 'high', label: LocalizationService.tr('water_high')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedWater = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: LocalizationService.tr('save_changes'),
                    onPressed: () async {
                      final updatedFarm = {
                        'farmSizeAcres': double.tryParse(farmSizeController.text.trim()) ?? 2.0,
                        'defaultSoilType': selectedSoil,
                        'defaultWaterAvailability': selectedWater,
                      };

                      final updatedUser = user.copyWith(farmDetails: updatedFarm);
                      UserService.currentUser = updatedUser;

                      // Update Firestore
                      await FirestoreRefs.users.doc(user.uid).set(
                            updatedUser.toMap(),
                            SetOptions(merge: true),
                          );

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
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
          content: Text(LocalizationService.tr('profile_logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LocalizationService.tr('profile_cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
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
                          user?.name ?? 'AgroSaathi Farmer',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? 'No Phone Number',
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

            // Farm Details Section
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
                    (user?.farmDetails?['defaultWaterAvailability'] ?? 'Canal / Borewell').toString().toUpperCase(),
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