import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/growth_plan_model.dart';
import '../services/growth_plan_service.dart';
import '../services/localization_service.dart';
import '../services/user_service.dart';
import '../widgets/app_card.dart';
import '../widgets/growth_plan_card.dart';
import '../widgets/quick_module_tile.dart';
import '../widgets/weather_widget.dart';
import 'crop_setup_screen.dart';
import 'growth_plan_detail_screen.dart';

/// Rich Home Dashboard view with Weather, Quick Module Access, Active Growth Plans stream, and Tips.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser;
    final farmerId = user?.uid;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Farmer';

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, currentLang, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Header Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationService.tr('welcome_back')}, $userName 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocalizationService.tr('tagline'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco, color: AppColors.primary, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Agro-Weather Card
            const WeatherWidget(),
            const SizedBox(height: 20),

            // 4-Module Quick-Access Grid
            Text(
              LocalizationService.tr('quick_actions'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.02,
              children: [
                QuickModuleTile(
                  title: LocalizationService.tr('nav_advisor'),
                  description: LocalizationService.tr('crop_recommendations_sub'),
                  icon: Icons.psychology_outlined,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primaryLight,
                  onTap: () => onNavigateToTab?.call(1),
                ),
                QuickModuleTile(
                  title: LocalizationService.tr('nav_disease'),
                  description: LocalizationService.tr('disease_detector_sub'),
                  icon: Icons.bug_report_outlined,
                  iconColor: AppColors.warning,
                  iconBgColor: AppColors.warningLight,
                  onTap: () => onNavigateToTab?.call(2),
                ),
                QuickModuleTile(
                  title: LocalizationService.tr('nav_planner'),
                  description: LocalizationService.tr('growth_planner_sub'),
                  icon: Icons.timeline_outlined,
                  iconColor: AppColors.accent,
                  iconBgColor: AppColors.accentLight,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CropSetupScreen()),
                  ),
                ),
                QuickModuleTile(
                  title: LocalizationService.tr('nav_market'),
                  description: LocalizationService.tr('marketplace_sub'),
                  icon: Icons.storefront_outlined,
                  iconColor: AppColors.secondary,
                  iconBgColor: AppColors.secondaryLight,
                  onTap: () => onNavigateToTab?.call(3),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Growth Plans Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    LocalizationService.tr('active_growth_plans'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CropSetupScreen()),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(LocalizationService.tr('new_plan')),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (farmerId == null)
              AppCard(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  title: Text(LocalizationService.tr('sign_in_to_track')),
                  subtitle: const Text('Tap login to access growth plans and reminders'),
                ),
              )
            else
              StreamBuilder<List<GrowthPlan>>(
                stream: GrowthPlanService().streamUserPlans(farmerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final plans = snapshot.data ?? [];

                  if (plans.isEmpty) {
                    return AppCard(
                      child: ListTile(
                        leading: const Icon(Icons.timeline, color: AppColors.primary),
                        title: Text(LocalizationService.tr('no_active_plans')),
                        subtitle: Text(LocalizationService.tr('start_tracking_plan')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CropSetupScreen()),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: plans
                        .map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GrowthPlanCard(
                              plan: plan,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GrowthPlanDetailScreen(planId: plan.id),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Daily Farming Tip Card
            AppCard(
              backgroundColor: const Color(0xFFFFFDE7),
              borderColor: const Color(0xFFFFF59D),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFFFBC02D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.tr('daily_tip_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocalizationService.tr('daily_tip_body'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}