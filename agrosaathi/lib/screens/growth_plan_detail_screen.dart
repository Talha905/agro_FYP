import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/firestore_constants.dart';
import '../models/growth_plan_model.dart';
import '../services/growth_plan_service.dart';
import '../services/notification_service.dart';

class GrowthPlanDetailScreen extends StatefulWidget {
  final String planId;
  const GrowthPlanDetailScreen({super.key, required this.planId});

  @override
  State<GrowthPlanDetailScreen> createState() => _GrowthPlanDetailScreenState();
}

class _GrowthPlanDetailScreenState extends State<GrowthPlanDetailScreen> {
  final GrowthPlanService _service = GrowthPlanService();

  Future<void> _handleMenuAction(String action, GrowthPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(action == 'complete' ? 'Mark as Harvested?' : 'Abandon this plan?'),
        content: Text(
          action == 'complete'
              ? 'This closes the plan and stops future reminders for it.'
              : 'This stops tracking the plan and cancels its reminders. This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    await NotificationService.cancelForPlan(plan.id, plan);
    if (action == 'complete') {
      await _service.completePlan(plan.id);
    } else {
      await _service.abandonPlan(plan.id);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirestoreCollections.growthPlans)
            .doc(widget.planId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final plan = GrowthPlan.fromMap(snapshot.data!.id, snapshot.data!.data()!);

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Growth Plan'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (action) => _handleMenuAction(action, plan),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'complete', child: Text('Mark as Harvested')),
                    PopupMenuItem(value: 'abandon', child: Text('Abandon Plan')),
                  ],
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Irrigation'),
                  Tab(text: 'Fertilizer'),
                  Tab(text: 'Pests'),
                ],
              ),
            ),
            body: Column(
              children: [
                _HarvestCountdown(plan: plan),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TimelineTab(plan: plan),
                      _IrrigationTab(plan: plan, service: _service),
                      _FertilizerTab(plan: plan, service: _service),
                      _PestTab(plan: plan),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HarvestCountdown extends StatelessWidget {
  final GrowthPlan plan;
  const _HarvestCountdown({required this.plan});

  @override
  Widget build(BuildContext context) {
    final days = plan.expectedHarvestDate.difference(DateTime.now()).inDays;
    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            plan.cropName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            days > 0 ? '$days days to expected harvest' : 'Harvest window reached',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final GrowthPlan plan;
  const _TimelineTab({required this.plan});

  static const stages = ['sowing', 'germination', 'vegetative', 'flowering', 'maturity', 'harvested'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = stages.indexOf(plan.currentStage);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final isPast = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isPast ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.circle_outlined),
                  color: isPast || isCurrent ? AppColors.primary : AppColors.textSecondary,
                ),
                if (index != stages.length - 1)
                  Container(width: 2, height: 40, color: isPast ? AppColors.primary : Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 2),
              child: Text(
                stages[index][0].toUpperCase() + stages[index].substring(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IrrigationTab extends StatelessWidget {
  final GrowthPlan plan;
  final GrowthPlanService service;
  const _IrrigationTab({required this.plan, required this.service});

  @override
  Widget build(BuildContext context) {
    if (plan.irrigationSchedule.isEmpty) {
      return const Center(child: Text('No irrigation dates scheduled'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.irrigationSchedule.length,
      itemBuilder: (context, index) {
        final entry = plan.irrigationSchedule[index];
        final date = (entry['date'] as Timestamp).toDate();
        final completed = entry['completed'] == true;

        return CheckboxListTile(
          value: completed,
          activeColor: AppColors.accent,
          title: Text('${date.day}/${date.month}/${date.year}'),
          onChanged: (value) async {
            final updated = List<Map<String, dynamic>>.from(plan.irrigationSchedule);
            updated[index] = {...entry, 'completed': value};
            await service.markIrrigationDone(plan.id, updated);
          },
        );
      },
    );
  }
}

class _FertilizerTab extends StatelessWidget {
  final GrowthPlan plan;
  final GrowthPlanService service;
  const _FertilizerTab({required this.plan, required this.service});

  @override
  Widget build(BuildContext context) {
    if (plan.fertilizerSchedule.isEmpty) {
      return const Center(child: Text('No fertilizer applications scheduled'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.fertilizerSchedule.length,
      itemBuilder: (context, index) {
        final entry = plan.fertilizerSchedule[index];
        final date = (entry['applicationDate'] as Timestamp).toDate();
        final completed = entry['completed'] == true;

        return CheckboxListTile(
          value: completed,
          activeColor: AppColors.secondary,
          title: Text(entry['fertilizerType']),
          subtitle: Text('${entry['stage']} stage · ${date.day}/${date.month}/${date.year}'),
          onChanged: (value) async {
            final updated = List<Map<String, dynamic>>.from(plan.fertilizerSchedule);
            updated[index] = {...entry, 'completed': value};
            await service.markFertilizerDone(plan.id, updated);
          },
        );
      },
    );
  }
}

class _PestTab extends StatelessWidget {
  final GrowthPlan plan;
  const _PestTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan.pestControlReminders.isEmpty) {
      return const Center(child: Text('No pest alerts for this crop cycle'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.pestControlReminders.length,
      itemBuilder: (context, index) {
        final entry = plan.pestControlReminders[index];
        final date = (entry['date'] as Timestamp).toDate();

        return Card(
          color: AppColors.warning.withValues(alpha: 0.06),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            title: Text(entry['message']),
            subtitle: Text('${date.day}/${date.month}/${date.year}'),
          ),
        );
      },
    );
  }
}
