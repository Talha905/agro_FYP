import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_constants.dart';
import '../data/crop_growth_templates.dart';
import '../models/growth_plan_model.dart';
import 'growth_plan_generator.dart';

class GrowthPlanService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String> createPlan(GrowthPlan plan) async {
    final docRef = await firestore
        .collection(FirestoreCollections.growthPlans)
        .add(plan.toMap());
    return docRef.id;
  }

  /// Active plans for a farmer, newest first.
  /// Sorted client-side (not via orderBy) so this only needs the
  /// farmerId + status composite index already listed in the schema doc.
  Stream<List<GrowthPlan>> streamUserPlans(String farmerId) {
    return firestore
        .collection(FirestoreCollections.growthPlans)
        .where('farmerId', isEqualTo: farmerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
      final plans = snap.docs.map((d) => GrowthPlan.fromMap(d.id, d.data())).toList();
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plans;
    });
  }

  Future<GrowthPlan?> getPlan(String planId) async {
    final doc = await firestore.collection(FirestoreCollections.growthPlans).doc(planId).get();
    if (!doc.exists) return null;
    return GrowthPlan.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateCurrentStage(String planId, String newStage) async {
    await firestore.collection(FirestoreCollections.growthPlans).doc(planId).update({
      'currentStage': newStage,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markIrrigationDone(String planId, List<Map<String, dynamic>> updatedSchedule) async {
    await firestore.collection(FirestoreCollections.growthPlans).doc(planId).update({
      'irrigationSchedule': updatedSchedule,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markFertilizerDone(String planId, List<Map<String, dynamic>> updatedSchedule) async {
    await firestore.collection(FirestoreCollections.growthPlans).doc(planId).update({
      'fertilizerSchedule': updatedSchedule,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> setStatus(String planId, String status) async {
    await firestore.collection(FirestoreCollections.growthPlans).doc(planId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Marks a plan finished: status -> completed, currentStage -> harvested.
  Future<void> completePlan(String planId) async {
    await firestore.collection(FirestoreCollections.growthPlans).doc(planId).update({
      'status': 'completed',
      'currentStage': 'harvested',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> abandonPlan(String planId) async {
    await setStatus(planId, 'abandoned');
  }

  /// One-off check (not a live listener): for every active plan a farmer has,
  /// recompute what stage they *should* be in today based on elapsed days,
  /// and update Firestore if it's drifted. Call this once per app session
  /// (e.g. from DashboardScreen.initState) rather than on every rebuild.
  Future<void> syncStagesForFarmer(String farmerId) async {
    final snap = await firestore
        .collection(FirestoreCollections.growthPlans)
        .where('farmerId', isEqualTo: farmerId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in snap.docs) {
      final plan = GrowthPlan.fromMap(doc.id, doc.data());

      CropGrowthTemplate? template;
      for (final t in CropTemplates.all) {
        if (t.cropSlug == plan.cropId) {
          template = t;
          break;
        }
      }
      if (template == null) continue; // unknown/legacy cropId, skip rather than guess

      final expectedStage = GrowthPlanGenerator.currentStageFor(template, plan.plantingDate);
      if (expectedStage != plan.currentStage) {
        await updateCurrentStage(plan.id, expectedStage);
      }
    }
  }
}
