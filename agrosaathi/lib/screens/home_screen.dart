import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/growth_plan_model.dart';
import '../services/growth_plan_service.dart';
import '../services/user_service.dart';
import '../widgets/growth_plan_card.dart';
import 'crop_setup_screen.dart';
import 'growth_plan_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmerId = UserService.currentUser?.uid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Weather'),
            subtitle: Text('Weather data will appear here'),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Growth Planner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CropSetupScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Plan'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (farmerId == null)
          const Text('Sign in to track your crop growth.')
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
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.timeline),
                    title: Text('No active growth plans'),
                    subtitle: Text('Tap "New Plan" to start tracking a crop'),
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
                            MaterialPageRoute(builder: (_) => GrowthPlanDetailScreen(planId: plan.id)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),

        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text('Recommendations'),
            subtitle: Text('Personalized farming advice'),
          ),
        ),
      ],
    );
  }
}
