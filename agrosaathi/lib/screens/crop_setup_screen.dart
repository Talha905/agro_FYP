import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/crop_growth_templates.dart';
import '../services/growth_plan_generator.dart';
import '../services/growth_plan_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class CropSetupScreen extends StatefulWidget {
  const CropSetupScreen({super.key});

  @override
  State<CropSetupScreen> createState() => _CropSetupScreenState();
}

class _CropSetupScreenState extends State<CropSetupScreen> {
  CropGrowthTemplate? selectedCrop;
  DateTime? plantingDate;
  bool saving = false;

  final GrowthPlanService _planService = GrowthPlanService();

  Future<void> _submit() async {
    if (selectedCrop == null || plantingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop and planting date')),
      );
      return;
    }

    final farmerId = UserService.currentUser?.uid;
    if (farmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to create a plan')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final plan = GrowthPlanGenerator.generate(
        farmerId: farmerId,
        template: selectedCrop!,
        plantingDate: plantingDate!,
      );

      final planId = await _planService.createPlan(plan);

      // Notifications are a nice-to-have on top of a successfully saved plan —
      // don't let a permissions/OS quirk make this look like plan creation failed.
      try {
        await NotificationService.scheduleForPlan(planId, plan);
      } catch (notificationError) {
        debugPrint('Notification scheduling failed (plan was still saved): $notificationError');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Start a New Growth Plan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<CropGrowthTemplate>(
              initialValue: selectedCrop,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: const Text('Select a crop'),
              items: CropTemplates.all
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCrop = value),
            ),
            const SizedBox(height: 24),
            const Text('Planting Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => plantingDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(
                  plantingDate == null
                      ? 'Select a date'
                      : '${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}',
                ),
              ),
            ),
            if (selectedCrop != null) ...[
              const SizedBox(height: 16),
              Text(
                'Expected cycle length: ${selectedCrop!.totalDurationDays} days',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: saving ? null : _submit,
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Growth Plan', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
