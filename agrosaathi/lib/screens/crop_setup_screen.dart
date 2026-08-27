import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/crop_growth_templates.dart';
import '../services/ai_growth_plan_service.dart';
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
  final _cropController = TextEditingController();
  final _soilController = TextEditingController();
  final _seasonController = TextEditingController();

  DateTime? plantingDate;
  bool saving = false;
  String? statusMessage; // shown while AI call is in flight / on fallback

  final GrowthPlanService _planService = GrowthPlanService();

  @override
  void dispose() {
    _cropController.dispose();
    _soilController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  /// Finds a static template whose slug or display name loosely matches
  /// what the farmer typed — used only as a fallback when the AI call fails.
  CropGrowthTemplate? _matchStaticTemplate(String typedName) {
    final normalized = typedName.trim().toLowerCase();
    for (final t in CropTemplates.all) {
      if (t.cropSlug == normalized || t.displayName.toLowerCase() == normalized) {
        return t;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final cropName = _cropController.text.trim();

    if (cropName.isEmpty || plantingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a crop name and planting date')),
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

    setState(() {
      saving = true;
      statusMessage = 'Asking AI to design your ${cropName.isEmpty ? 'crop' : cropName} plan…';
    });

    CropGrowthTemplate? template;

    try {
      template = await AIGrowthPlanService.generate(
        cropName: cropName,
        soilType: _soilController.text.trim().isEmpty ? null : _soilController.text.trim(),
        season: _seasonController.text.trim().isEmpty ? null : _seasonController.text.trim(),
      );
    } catch (e) {
      // AI failed (offline, backend down, unrecognized crop, etc).
      // Fall back to a static template only if the typed name matches one
      // of our 7 known crops — otherwise we genuinely can't build a plan.
      final fallback = _matchStaticTemplate(cropName);
      if (fallback != null) {
        template = fallback;
        setState(() => statusMessage = 'AI unavailable — using a saved template for ${fallback.displayName} instead.');
        await Future.delayed(const Duration(seconds: 1)); // let the farmer read the message
      } else {
        setState(() {
          saving = false;
          statusMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Couldn\'t generate a plan for "$cropName" right now (${e.toString()}). '
                'Check your connection, or try a common crop name like Wheat or Rice.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final plan = GrowthPlanGenerator.generate(
        farmerId: farmerId,
        template: template,
        plantingDate: plantingDate!,
      );

      final planId = await _planService.createPlan(plan);
      await NotificationService.scheduleForPlan(planId, plan);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save plan: $e')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _cropController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. Wheat, Okra, Turmeric…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Soil type (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _soilController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. black cotton soil, loamy…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Season (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _seasonController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. rabi, kharif…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
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

            if (statusMessage != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (saving)
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    ),
                  if (saving) const SizedBox(width: 8),
                  Expanded(
                    child: Text(statusMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
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
