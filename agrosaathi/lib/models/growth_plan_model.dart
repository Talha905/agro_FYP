import 'package:cloud_firestore/cloud_firestore.dart';

/// Matches the `growthPlans` collection in the Firestore Schema doc.
/// One document per active crop cycle a farmer is tracking.
class GrowthPlan {
  final String id; // Firestore doc id (empty until saved)
  final String farmerId;
  final String cropId; // maps to cropCatalog doc / local template slug
  final String cropName; // denormalized for display without extra reads
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final String currentStage; // sowing | germination | vegetative | flowering | maturity | harvested
  final List<Map<String, dynamic>> irrigationSchedule; // [{date, completed}]
  final List<Map<String, dynamic>> fertilizerSchedule; // [{stage, fertilizerType, applicationDate, completed}]
  final List<Map<String, dynamic>> pestControlReminders; // [{date, message, completed}]
  final String status; // active | completed | abandoned
  final DateTime createdAt;
  final DateTime updatedAt;

  GrowthPlan({
    required this.id,
    required this.farmerId,
    required this.cropId,
    required this.cropName,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.currentStage,
    required this.irrigationSchedule,
    required this.fertilizerSchedule,
    required this.pestControlReminders,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cropId': cropId,
      'cropName': cropName,
      'plantingDate': Timestamp.fromDate(plantingDate),
      'expectedHarvestDate': Timestamp.fromDate(expectedHarvestDate),
      'currentStage': currentStage,
      'irrigationSchedule': irrigationSchedule,
      'fertilizerSchedule': fertilizerSchedule,
      'pestControlReminders': pestControlReminders,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GrowthPlan.fromMap(String id, Map<String, dynamic> map) {
    return GrowthPlan(
      id: id,
      farmerId: map['farmerId'],
      cropId: map['cropId'],
      cropName: map['cropName'] ?? '',
      plantingDate: (map['plantingDate'] as Timestamp).toDate(),
      expectedHarvestDate: (map['expectedHarvestDate'] as Timestamp).toDate(),
      currentStage: map['currentStage'],
      irrigationSchedule: List<Map<String, dynamic>>.from(map['irrigationSchedule'] ?? []),
      fertilizerSchedule: List<Map<String, dynamic>>.from(map['fertilizerSchedule'] ?? []),
      pestControlReminders: List<Map<String, dynamic>>.from(map['pestControlReminders'] ?? []),
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  GrowthPlan copyWith({
    List<Map<String, dynamic>>? irrigationSchedule,
    List<Map<String, dynamic>>? fertilizerSchedule,
    String? currentStage,
    String? status,
  }) {
    return GrowthPlan(
      id: id,
      farmerId: farmerId,
      cropId: cropId,
      cropName: cropName,
      plantingDate: plantingDate,
      expectedHarvestDate: expectedHarvestDate,
      currentStage: currentStage ?? this.currentStage,
      irrigationSchedule: irrigationSchedule ?? this.irrigationSchedule,
      fertilizerSchedule: fertilizerSchedule ?? this.fertilizerSchedule,
      pestControlReminders: pestControlReminders,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
