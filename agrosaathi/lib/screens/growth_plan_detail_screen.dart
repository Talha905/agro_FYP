import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/firestore_constants.dart';
import '../models/growth_plan_model.dart';
import '../services/growth_plan_generator.dart';
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

  /// Opens the Adaptive Rescheduling Modal ("Room for Errors")
  Future<void> _showRescheduleDialog(GrowthPlan plan, {int suggestedDelayDays = 3}) async {
    int selectedDays = suggestedDelayDays > 0 ? suggestedDelayDays : 3;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final newHarvest = plan.expectedHarvestDate.add(Duration(days: selectedDays));
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.auto_mode, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(child: Text('Adaptive Reschedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Farming life has unexpected delays! Adjust your schedule below — AgroSaathi will recalculate future task dates & harvest countdown.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delay Amount: +$selectedDays ${selectedDays == 1 ? 'Day' : 'Days'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Slider(
                  value: selectedDays.toDouble(),
                  min: 1,
                  max: 14,
                  divisions: 13,
                  label: '+$selectedDays Days',
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setModalState(() => selectedDays = val.toInt());
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_month, size: 16, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text('Shifted Impact Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Remaining task dates: Shifted by +$selectedDays days\n'
                        '• New Expected Harvest: ${newHarvest.day}/${newHarvest.month}/${newHarvest.year}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Apply Reschedule'),
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    try {
      final rescheduledPlan = GrowthPlanGenerator.adaptivelyReschedule(plan, delayDays: selectedDays);
      await _service.updatePlanReschedule(rescheduledPlan);

      // Re-schedule local notifications with shifted dates
      try {
        await NotificationService.cancelForPlan(plan.id, plan);
        await NotificationService.scheduleForPlan(plan.id, rescheduledPlan);
      } catch (e) {
        debugPrint('Failed to reschedule notifications: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan rescheduled by +$selectedDays days! Harvest updated to ${rescheduledPlan.expectedHarvestDate.day}/${rescheduledPlan.expectedHarvestDate.month}/${rescheduledPlan.expectedHarvestDate.year}.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule: $e')),
        );
      }
    }
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

          // Check if any uncompleted task is overdue
          int overdueDays = 0;
          final now = DateTime.now();
          for (final item in plan.irrigationSchedule) {
            if (item['completed'] != true) {
              final d = (item['date'] as Timestamp).toDate();
              if (d.isBefore(now.subtract(const Duration(days: 1)))) {
                final diff = now.difference(d).inDays;
                if (diff > overdueDays) overdueDays = diff;
              }
            }
          }
          for (final item in plan.fertilizerSchedule) {
            if (item['completed'] != true) {
              final d = (item['applicationDate'] as Timestamp).toDate();
              if (d.isBefore(now.subtract(const Duration(days: 1)))) {
                final diff = now.difference(d).inDays;
                if (diff > overdueDays) overdueDays = diff;
              }
            }
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(plan.cropName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Colors.white),
                  tooltip: 'Reschedule Plan',
                  onPressed: () => _showRescheduleDialog(plan, suggestedDelayDays: overdueDays > 0 ? overdueDays : 3),
                ),
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
                indicatorColor: Colors.white,
                indicatorWeight: 3,
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
                _HarvestCountdown(plan: plan, overdueDays: overdueDays, onRescheduleTap: () => _showRescheduleDialog(plan, suggestedDelayDays: overdueDays > 0 ? overdueDays : 3)),
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
  final int overdueDays;
  final VoidCallback onRescheduleTap;

  const _HarvestCountdown({required this.plan, required this.overdueDays, required this.onRescheduleTap});

  @override
  Widget build(BuildContext context) {
    final days = plan.expectedHarvestDate.difference(DateTime.now()).inDays;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.cropName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stage: ${plan.currentStage.toUpperCase()}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      days > 0 ? '$days days left' : 'Harvest ready',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Overdue Task Banner with Instant Reschedule Option
          if (overdueDays > 0) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onRescheduleTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Overdue by ~$overdueDays ${overdueDays == 1 ? 'day' : 'days'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const Text(
                            'Tap to adaptively shift your schedule and harvest timeline.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warning),
                  ],
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(20),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final isPast = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isPast || isCurrent ? AppColors.primaryLight : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPast ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.circle_outlined),
                    color: isPast || isCurrent ? AppColors.primary : AppColors.textDisabled,
                    size: 22,
                  ),
                ),
                if (index != stages.length - 1)
                  Container(width: 2, height: 44, color: isPast ? AppColors.primary : Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 2),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primaryLight.withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : AppColors.cardBorder,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stages[index][0].toUpperCase() + stages[index].substring(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
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
        final isOverdue = !completed && date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isOverdue ? AppColors.warning : AppColors.cardBorder),
          ),
          child: CheckboxListTile(
            value: completed,
            activeColor: AppColors.accent,
            title: Text(
              'Irrigation Session ${index + 1}',
              style: TextStyle(fontWeight: FontWeight.bold, decoration: completed ? TextDecoration.lineThrough : null),
            ),
            subtitle: Text(
              'Date: ${date.day}/${date.month}/${date.year} ${isOverdue ? '• Overdue' : ''}',
              style: TextStyle(color: isOverdue ? AppColors.warning : AppColors.textSecondary, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
            ),
            onChanged: (value) async {
              final updated = List<Map<String, dynamic>>.from(plan.irrigationSchedule);
              updated[index] = {...entry, 'completed': value};
              await service.markIrrigationDone(plan.id, updated);
            },
          ),
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
        final isOverdue = !completed && date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isOverdue ? AppColors.warning : AppColors.cardBorder),
          ),
          child: CheckboxListTile(
            value: completed,
            activeColor: AppColors.secondary,
            title: Text(
              entry['fertilizerType'],
              style: TextStyle(fontWeight: FontWeight.bold, decoration: completed ? TextDecoration.lineThrough : null),
            ),
            subtitle: Text(
              '${entry['stage'].toString().toUpperCase()} Stage • ${date.day}/${date.month}/${date.year}',
              style: TextStyle(color: isOverdue ? AppColors.warning : AppColors.textSecondary),
            ),
            onChanged: (value) async {
              final updated = List<Map<String, dynamic>>.from(plan.fertilizerSchedule);
              updated[index] = {...entry, 'completed': value};
              await service.markFertilizerDone(plan.id, updated);
            },
          ),
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
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          color: AppColors.warningLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: const Icon(Icons.bug_report, color: AppColors.warning),
            title: Text(entry['message'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Stage Milestone: ${date.day}/${date.month}/${date.year}'),
          ),
        );
      },
    );
  }
}
