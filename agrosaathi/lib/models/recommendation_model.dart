import 'package:cloud_firestore/cloud_firestore.dart';

/// User inputs for crop recommendation request.
class RecommendationInput {
  final String soilType; // alluvial | black | red | clay | sandy | loamy | laterite
  final String season; // kharif | rabi | zaid
  final String waterAvailability; // low | medium | high
  final String district;
  final double farmSizeAcres;
  final double? nitrogen; // N in kg/ha
  final double? phosphorus; // P in kg/ha
  final double? potassium; // K in kg/ha
  final double? ph; // soil pH

  RecommendationInput({
    required this.soilType,
    required this.season,
    required this.waterAvailability,
    this.district = 'Maharashtra',
    this.farmSizeAcres = 1.0,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.ph,
  });

  Map<String, dynamic> toMap() {
    return {
      'soilType': soilType,
      'season': season,
      'waterAvailability': waterAvailability,
      'district': district,
      'farmSizeAcres': farmSizeAcres,
      if (nitrogen != null) 'nitrogen': nitrogen,
      if (phosphorus != null) 'phosphorus': phosphorus,
      if (potassium != null) 'potassium': potassium,
      if (ph != null) 'ph': ph,
    };
  }

  factory RecommendationInput.fromMap(Map<String, dynamic> map) {
    return RecommendationInput(
      soilType: map['soilType'] ?? 'black',
      season: map['season'] ?? 'kharif',
      waterAvailability: map['waterAvailability'] ?? 'medium',
      district: map['district'] ?? 'Maharashtra',
      farmSizeAcres: (map['farmSizeAcres'] as num?)?.toDouble() ?? 1.0,
      nitrogen: (map['nitrogen'] as num?)?.toDouble(),
      phosphorus: (map['phosphorus'] as num?)?.toDouble(),
      potassium: (map['potassium'] as num?)?.toDouble(),
      ph: (map['ph'] as num?)?.toDouble(),
    );
  }
}

/// Single crop recommendation result entry.
class CropRecommendationOutput {
  final String cropId;
  final String cropName; // Localized or common name
  final double estimatedProfit; // Profit per acre in INR (₹)
  final String waterRequirement; // 'low' | 'medium' | 'high'
  final String riskLevel; // 'low' | 'medium' | 'high'
  final double confidenceScore; // 0.0 - 1.0
  final int suitabilityScore; // 0 - 100%
  final int growthDurationDays;
  final String sowingWindow;
  final String agronomicTips;
  final double estimatedYieldQuintal;
  final double estimatedRevenue;
  final double estimatedCost;

  CropRecommendationOutput({
    required this.cropId,
    required this.cropName,
    required this.estimatedProfit,
    required this.waterRequirement,
    required this.riskLevel,
    required this.confidenceScore,
    this.suitabilityScore = 90,
    this.growthDurationDays = 110,
    this.sowingWindow = 'June - July',
    this.agronomicTips = '',
    this.estimatedYieldQuintal = 15.0,
    this.estimatedRevenue = 45000.0,
    this.estimatedCost = 15000.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'cropName': cropName,
      'estimatedProfit': estimatedProfit,
      'waterRequirement': waterRequirement,
      'riskLevel': riskLevel,
      'confidenceScore': confidenceScore,
      'suitabilityScore': suitabilityScore,
      'growthDurationDays': growthDurationDays,
      'sowingWindow': sowingWindow,
      'agronomicTips': agronomicTips,
      'estimatedYieldQuintal': estimatedYieldQuintal,
      'estimatedRevenue': estimatedRevenue,
      'estimatedCost': estimatedCost,
    };
  }

  factory CropRecommendationOutput.fromMap(Map<String, dynamic> map) {
    return CropRecommendationOutput(
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      estimatedProfit: (map['estimatedProfit'] as num?)?.toDouble() ?? 0.0,
      waterRequirement: map['waterRequirement'] ?? 'medium',
      riskLevel: map['riskLevel'] ?? 'low',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.85,
      suitabilityScore: (map['suitabilityScore'] as num?)?.toInt() ?? 90,
      growthDurationDays: (map['growthDurationDays'] as num?)?.toInt() ?? 100,
      sowingWindow: map['sowingWindow'] ?? '',
      agronomicTips: map['agronomicTips'] ?? '',
      estimatedYieldQuintal: (map['estimatedYieldQuintal'] as num?)?.toDouble() ?? 15.0,
      estimatedRevenue: (map['estimatedRevenue'] as num?)?.toDouble() ?? 45000.0,
      estimatedCost: (map['estimatedCost'] as num?)?.toDouble() ?? 15000.0,
    );
  }
}

/// Full Recommendation document stored in Firestore collection `recommendations`.
class RecommendationRecord {
  final String id;
  final String farmerId;
  final RecommendationInput input;
  final List<CropRecommendationOutput> output;
  final DateTime createdAt;

  RecommendationRecord({
    required this.id,
    required this.farmerId,
    required this.input,
    required this.output,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'input': input.toMap(),
      'output': output.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RecommendationRecord.fromMap(String id, Map<String, dynamic> map) {
    return RecommendationRecord(
      id: id,
      farmerId: map['farmerId'] ?? '',
      input: RecommendationInput.fromMap(
        Map<String, dynamic>.from(map['input'] ?? {}),
      ),
      output: (map['output'] as List<dynamic>?)
              ?.map((e) => CropRecommendationOutput.fromMap(
                    Map<String, dynamic>.from(e),
                  ))
              .toList() ??
          [],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
