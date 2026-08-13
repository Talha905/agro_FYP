import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/growth_plan_model.dart';

/// Compact card shown in the Home dashboard list of active growth plans.
class GrowthPlanCard extends StatelessWidget {
  final GrowthPlan plan;
  final VoidCallback onTap;

  const GrowthPlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysToHarvest = plan.expectedHarvestDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.grass, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.cropName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stage: ${_capitalize(plan.currentStage)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    daysToHarvest > 0 ? '$daysToHarvest days' : 'Ready',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                  const Text('to harvest', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
