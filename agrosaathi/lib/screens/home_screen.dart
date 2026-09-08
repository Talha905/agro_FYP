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

/// Redesigned Home Dashboard with Hero Header, Agro-Weather Card, Quick Actions & Metrics.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

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
            // Dynamic Time-of-Day Hero Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTimeGreeting(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Profile Avatar Badge
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              '${user?.role ?? 'Farmer'} Account',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('AI Enabled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Agro-Weather Card
            const WeatherWidget(),
            const SizedBox(height: 24),

            // 4-Module Quick-Access Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocalizationService.tr('quick_actions'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('4 Modules', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.02,
              children: [
                QuickModuleTile(
                  title: LocalizationService.tr('nav_advisor'),
                  description: LocalizationService.tr('crop_recommendations_sub'),
                  icon: Icons.psychology_rounded,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primaryLight,
                  onTap: () => onNavigateToTab?.call(1),
                ),
                QuickModuleTile(
                  title: LocalizationService.tr('nav_disease'),
                  description: LocalizationService.tr('disease_detector_sub'),
                  icon: Icons.bug_report_rounded,
                  iconColor: AppColors.warning,
                  iconBgColor: AppColors.warningLight,
                  onTap: () => onNavigateToTab?.call(2),
                ),
                QuickModuleTile(
                  title: LocalizationService.tr('nav_planner'),
                  description: LocalizationService.tr('growth_planner_sub'),
                  icon: Icons.timeline_rounded,
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
                  icon: Icons.storefront_rounded,
                  iconColor: AppColors.secondary,
                  iconBgColor: AppColors.secondaryLight,
                  onTap: () => onNavigateToTab?.call(3),
                ),
              ],
            ),
            const SizedBox(height: 28),

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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CropSetupScreen()),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(LocalizationService.tr('new_plan'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                      padding: const EdgeInsets.all(18),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.eco_rounded, color: AppColors.primary),
                        ),
                        title: Text(LocalizationService.tr('no_active_plans'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(LocalizationService.tr('start_tracking_plan')),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
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
            const SizedBox(height: 20),

            // Daily Farming Tip Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A)),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.tr('daily_tip_title'),
                          style: const TextStyle(
                            fontSize: 15,
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
                            height: 1.4,
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