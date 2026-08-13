import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/crop_growth_templates.dart';
import '../models/growth_plan_model.dart';

/// Turns a CropGrowthTemplate + planting date into a fully populated
/// GrowthPlan: harvest date, irrigation dates, fertilizer dates, pest reminders.
class GrowthPlanGenerator {
  static GrowthPlan generate({
    required String farmerId,
    required CropGrowthTemplate template,
    required DateTime plantingDate,
  }) {
    final harvestDate = plantingDate.add(Duration(days: template.totalDurationDays));

    // Start date of each stage, keyed by stage name.
    final stageStartDates = <String, DateTime>{};
    int offset = 0;
    for (final stage in template.stages) {
      stageStartDates[stage.name] = plantingDate.add(Duration(days: offset));
      offset += stage.durationDays;
    }

    // Irrigation: walk every stage, drop a date every `irrigationFrequencyDays`.
    final irrigationSchedule = <Map<String, dynamic>>[];
    offset = 0;
    for (final stage in template.stages) {
      final stageStart = plantingDate.add(Duration(days: offset));
      for (int d = 0; d < stage.durationDays; d += stage.irrigationFrequencyDays) {
        irrigationSchedule.add({
          'date': Timestamp.fromDate(stageStart.add(Duration(days: d))),
          'completed': false,
        });
      }
      offset += stage.durationDays;
    }

    // Fertilizer: one entry per FertilizerStep, anchored to its stage's start date.
    final fertilizerSchedule = template.fertilizerPlan.map((f) {
      final stageStart = stageStartDates[f.stageName]!;
      return {
        'stage': f.stageName,
        'fertilizerType': f.fertilizerType,
        'applicationDate': Timestamp.fromDate(stageStart.add(Duration(days: f.dayOffsetInStage))),
        'completed': false,
      };
    }).toList();

    // Pest reminders: one per stage that has known risks, fired at stage start.
    final pestControlReminders = <Map<String, dynamic>>[];
    for (final stage in template.stages) {
      if (stage.pestRisks.isNotEmpty) {
        pestControlReminders.add({
          'date': Timestamp.fromDate(stageStartDates[stage.name]!),
          'message': 'Watch for ${stage.pestRisks.join(', ')} during the ${stage.name} stage',
          'completed': false,
        });
      }
    }

    final now = DateTime.now();

    return GrowthPlan(
      id: '',
      farmerId: farmerId,
      // NOTE (integration): cropId is the local template slug (e.g. "wheat") for
      // now. Once Person A/C's `cropCatalog` collection is populated, swap this
      // for the real cropCatalog doc ID — everything else (schedules, screens)
      // stays the same since they only key off cropName for display.
      cropId: template.cropSlug,
      cropName: template.displayName,
      plantingDate: plantingDate,
      expectedHarvestDate: harvestDate,
      currentStage: template.stages.first.name,
      irrigationSchedule: irrigationSchedule,
      fertilizerSchedule: fertilizerSchedule,
      pestControlReminders: pestControlReminders,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Computes what stage a plan *should* be in today, based on elapsed days.
  /// Call this periodically (e.g. on app open) to auto-advance `currentStage`.
  static String currentStageFor(CropGrowthTemplate template, DateTime plantingDate) {
    final daysSincePlanting = DateTime.now().difference(plantingDate).inDays;
    int offset = 0;
    for (final stage in template.stages) {
      offset += stage.durationDays;
      if (daysSincePlanting < offset) return stage.name;
    }
    return 'maturity';
  }
}
