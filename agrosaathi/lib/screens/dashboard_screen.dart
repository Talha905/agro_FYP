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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationService.tr('profile_language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: const Text('English'),
                trailing: LocalizationService.currentLocale.value == 'en'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocalizationService.setLocale('en');
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: const Text('हिन्दी (Hindi)'),
                trailing: LocalizationService.currentLocale.value == 'hi'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocalizationService.setLocale('hi');
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: const Text('मराठी (Marathi)'),
                trailing: LocalizationService.currentLocale.value == 'mr'
                    ? const Icon(Icons.check, color: AppColors.primary)
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
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.tr('app_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            actions: [
              // Language Switcher Chip
              ActionChip(
                avatar: const Icon(Icons.language, size: 16, color: AppColors.primary),
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
                          const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
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
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: LocalizationService.tr('nav_home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.psychology_outlined),
                selectedIcon: const Icon(Icons.psychology),
                label: LocalizationService.tr('nav_advisor'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.bug_report_outlined),
                selectedIcon: const Icon(Icons.bug_report),
                label: LocalizationService.tr('nav_disease'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront),
                label: LocalizationService.tr('nav_market'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: LocalizationService.tr('nav_profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}