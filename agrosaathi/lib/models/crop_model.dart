/// Master Crop Catalog model matching the Firestore `cropCatalog` schema.
class CropModel {
  final String id;
  final Map<String, String> name; // { 'en': 'Wheat', 'hi': 'गेहूं', 'mr': 'गहू' }
  final String category; // 'cereal' | 'cash crop' | 'pulse' | 'vegetable' | 'fruit'
  final int growthDurationDays;
  final List<String> idealSoilTypes;
  final List<String> idealSeasons; // ['kharif', 'rabi', 'zaid']
  final String waterRequirement; // 'low' | 'medium' | 'high'
  final String? imageUrl;
  final double estimatedYieldQuintalPerAcre;
  final double basePricePerQuintal;
  final double cultivationCostPerAcre;
  final String riskLevel; // 'low' | 'medium' | 'high'
  final String? agronomicTips;

  CropModel({
    required this.id,
    required this.name,
    required this.category,
    required this.growthDurationDays,
    required this.idealSoilTypes,
    required this.idealSeasons,
    required this.waterRequirement,
    this.imageUrl,
    this.estimatedYieldQuintalPerAcre = 20.0,
    this.basePricePerQuintal = 2500.0,
    this.cultivationCostPerAcre = 15000.0,
    this.riskLevel = 'low',
    this.agronomicTips,
  });

  String getLocalizedName(String langCode) {
    return name[langCode] ?? name['en'] ?? id;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'growthDurationDays': growthDurationDays,
      'idealSoilTypes': idealSoilTypes,
      'idealSeasons': idealSeasons,
      'waterRequirement': waterRequirement,
      'imageUrl': imageUrl ?? '',
      'estimatedYieldQuintalPerAcre': estimatedYieldQuintalPerAcre,
      'basePricePerQuintal': basePricePerQuintal,
      'cultivationCostPerAcre': cultivationCostPerAcre,
      'riskLevel': riskLevel,
      'agronomicTips': agronomicTips ?? '',
    };
  }

  factory CropModel.fromMap(String id, Map<String, dynamic> map) {
    return CropModel(
      id: id,
      name: Map<String, String>.from(map['name'] ?? {'en': id}),
      category: map['category'] ?? 'cereal',
      growthDurationDays: (map['growthDurationDays'] as num?)?.toInt() ?? 100,
      idealSoilTypes: List<String>.from(map['idealSoilTypes'] ?? []),
      idealSeasons: List<String>.from(map['idealSeasons'] ?? []),
      waterRequirement: map['waterRequirement'] ?? 'medium',
      imageUrl: map['imageUrl'],
      estimatedYieldQuintalPerAcre: (map['estimatedYieldQuintalPerAcre'] as num?)?.toDouble() ?? 20.0,
      basePricePerQuintal: (map['basePricePerQuintal'] as num?)?.toDouble() ?? 2500.0,
      cultivationCostPerAcre: (map['cultivationCostPerAcre'] as num?)?.toDouble() ?? 15000.0,
      riskLevel: map['riskLevel'] ?? 'low',
      agronomicTips: map['agronomicTips'],
    );
  }
}
