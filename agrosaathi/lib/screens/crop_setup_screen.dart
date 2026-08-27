import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../data/crop_growth_templates.dart';
import '../services/ai_growth_plan_service.dart';
import '../services/growth_plan_generator.dart';
import '../services/growth_plan_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

/// Screen to create a growth plan, calling Gemini AI backend (/generate-growth-plan)
/// with fallback to local static agronomic templates.
class CropSetupScreen extends StatefulWidget {
  final String? initialCropName;

  const CropSetupScreen({super.key, this.initialCropName});

  @override
  State<CropSetupScreen> createState() => _CropSetupScreenState();
}

class _CropSetupScreenState extends State<CropSetupScreen> {
  final TextEditingController _customCropController = TextEditingController();
  CropGrowthTemplate? selectedCrop;
  DateTime? plantingDate = DateTime.now();
  bool isCustom = false;
  bool saving = false;
  bool isGeneratingAI = false;

  final GrowthPlanService _planService = GrowthPlanService();

  @override
  void initState() {
    super.initState();
    if (widget.initialCropName != null && widget.initialCropName!.isNotEmpty) {
      final matched = CropTemplates.all.firstWhere(
        (t) => t.displayName.toLowerCase() == widget.initialCropName!.toLowerCase() ||
            t.cropSlug.toLowerCase() == widget.initialCropName!.toLowerCase(),
        orElse: () {
          isCustom = true;
          _customCropController.text = widget.initialCropName!;
          return CropTemplates.all.first;
        },
      );
      if (!isCustom) {
        selectedCrop = matched;
      }
    } else {
      selectedCrop = CropTemplates.all.first;
    }
  }

  @override
  void dispose() {
    _customCropController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cropName = isCustom
        ? _customCropController.text.trim()
        : selectedCrop?.displayName;

    if (cropName == null || cropName.isEmpty || plantingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a crop name and select a planting date')),
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
      isGeneratingAI = true;
    });

    try {
      CropGrowthTemplate templateToUse;
      final user = UserService.currentUser;
      final soilType = user?.farmDetails?['defaultSoilType'] as String?;

      // 1. Send Request to FastAPI Gemini AI Endpoint (/generate-growth-plan)
      try {
        templateToUse = await AIGrowthPlanService.generate(
          cropName: cropName,
          soilType: soilType,
          season: 'Kharif',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generated agronomic plan using Gemini AI! ✨'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (aiError) {
        debugPrint('Gemini AI Generation error (using template fallback): $aiError');
        // Fallback to local template matching
        templateToUse = selectedCrop ??
            CropTemplates.all.firstWhere(
              (t) => t.displayName.toLowerCase() == cropName.toLowerCase(),
              orElse: () => CropTemplates.generic(cropName),
            );
      }

      // 2. Generate GrowthPlan document with stage dates
      final plan = GrowthPlanGenerator.generate(
        farmerId: farmerId,
        template: templateToUse,
        plantingDate: plantingDate!,
      );

      // 3. Save to Firestore
      final planId = await _planService.createPlan(plan);

      // 4. Schedule local reminders
      try {
        await NotificationService.scheduleForPlan(planId, plan);
      } catch (notificationError) {
        debugPrint('Notification scheduling failed (plan saved): $notificationError');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
          isGeneratingAI = false;
        });
      }
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
            // Mode Segment Switcher
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Preset Crops'),
                    selected: !isCustom,
                    onSelected: (val) {
                      if (val) setState(() => isCustom = false);
                    },
                    selectedColor: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Custom AI Crop ✨'),
                    selected: isCustom,
                    onSelected: (val) {
                      if (val) setState(() => isCustom = true);
                    },
                    selectedColor: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!isCustom) ...[
              const Text('Select Pre-configured Crop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CropGrowthTemplate>(
                value: selectedCrop,
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
            ] else ...[
              const Text('Enter Any Crop Name (Gemini AI Powered)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _customCropController,
                decoration: InputDecoration(
                  hintText: 'e.g. Turmeric, Garlic, Chili, Papaya...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.auto_awesome, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Planting Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: plantingDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => plantingDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                ),
                child: Text(
                  plantingDate == null
                      ? 'Select a date'
                      : '${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}',
                ),
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Generation queries Gemini on the FastAPI backend to build customized stage timelines, irrigation intervals, and fertilizer plans.',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.auto_awesome, size: 18),
                onPressed: saving ? null : _submit,
                label: saving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Generating with Gemini AI...'),
                        ],
                      )
                    : const Text('Generate Growth Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
