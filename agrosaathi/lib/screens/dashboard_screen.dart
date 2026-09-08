import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/growth_plan_service.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'crop_advisor_screen.dart';
import 'disease_detector_screen.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

/// Central 5-tab Dashboard Navigation Shell integrating all team modules.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    LocalizationService.init();

    final farmerId = UserService.currentUser?.uid;
    if (farmerId != null) {
      GrowthPlanService().syncStagesForFarmer(farmerId).catchError((_) {});
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationService.tr('profile_language'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: LocalizationService.currentLocale.value == 'en'
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocalizationService.setLocale('en');
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                title: const Text('हिन्दी (Hindi)', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: LocalizationService.currentLocale.value == 'hi'
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocalizationService.setLocale('hi');
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                title: const Text('मराठी (Marathi)', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: LocalizationService.currentLocale.value == 'mr'
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocalizationService.setLocale('mr');
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = UserService.currentUser?.uid;

    final List<Widget> screens = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      const CropAdvisorScreen(),
      const DiseaseDetectorScreen(),
      const MarketplaceScreen(),
      const ProfileScreen(),
    ];

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, currentLang, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.surface,
            scrolledUnderElevation: 2,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  LocalizationService.tr('app_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              // Language Switcher Chip
              ActionChip(
                avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                label: Text(
                  currentLang.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                backgroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primary, width: 0.8),
                onPressed: _showLanguageSelector,
              ),
              const SizedBox(width: 6),

              // Notifications Bell with dynamic stream counter
              if (userId != null)
                StreamBuilder<int>(
                  stream: NotificationService().getUnreadCount(userId),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 26),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                    );
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    );
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              indicatorColor: AppColors.primaryLight,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primary),
                  label: LocalizationService.tr('nav_home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.psychology_outlined),
                  selectedIcon: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                  label: LocalizationService.tr('nav_advisor'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bug_report_outlined),
                  selectedIcon: const Icon(Icons.bug_report_rounded, color: AppColors.primary),
                  label: LocalizationService.tr('nav_disease'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  label: LocalizationService.tr('nav_market'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                  label: LocalizationService.tr('nav_profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}