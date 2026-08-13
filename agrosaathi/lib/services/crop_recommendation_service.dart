import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crop_model.dart';
import '../models/recommendation_model.dart';
import 'api_service.dart';
import 'firestore_refs.dart';

/// Agronomic Knowledgebase and ML Adapter for Crop Recommendation.
/// Owned by Person A. Supports both on-device agronomic scoring and backend model.pkl inference.
class CropRecommendationService {
  // Master Crop Knowledge Base with localized names, requirements, and economics
  static final List<CropModel> cropCatalog = [
    CropModel(
      id: 'wheat',
      name: {'en': 'Wheat', 'hi': 'गेहूं', 'mr': 'गहू'},
      category: 'cereal',
      growthDurationDays: 120,
      idealSoilTypes: ['alluvial', 'black', 'clay', 'loamy'],
      idealSeasons: ['rabi'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 18.5,
      basePricePerQuintal: 2350.0,
      cultivationCostPerAcre: 14000.0,
      riskLevel: 'low',
      agronomicTips: 'Sow in November - December. Ensure 4-5 irrigations at critical crown root initiation and flowering stages.',
    ),
    CropModel(
      id: 'rice',
      name: {'en': 'Rice (Paddy)', 'hi': 'धान / चावल', 'mr': 'भात / तांदूळ'},
      category: 'cereal',
      growthDurationDays: 135,
      idealSoilTypes: ['alluvial', 'clay', 'black', 'loamy'],
      idealSeasons: ['kharif'],
      waterRequirement: 'high',
      estimatedYieldQuintalPerAcre: 22.0,
      basePricePerQuintal: 2250.0,
      cultivationCostPerAcre: 18000.0,
      riskLevel: 'low',
      agronomicTips: 'Transplant 20-25 day old seedlings. Maintain 2-3 cm standing water during vegetative stage.',
    ),
    CropModel(
      id: 'cotton',
      name: {'en': 'Cotton', 'hi': 'कपास', 'mr': 'कापूस'},
      category: 'cash crop',
      growthDurationDays: 165,
      idealSoilTypes: ['black', 'alluvial', 'loamy'],
      idealSeasons: ['kharif'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 10.5,
      basePricePerQuintal: 7120.0,
      cultivationCostPerAcre: 24000.0,
      riskLevel: 'medium',
      agronomicTips: 'Thrives in black cotton soils. Monitor for bollworm infestation during flowering and boll formation.',
    ),
    CropModel(
      id: 'maize',
      name: {'en': 'Maize (Corn)', 'hi': 'मक्का', 'mr': 'मका'},
      category: 'cereal',
      growthDurationDays: 100,
      idealSoilTypes: ['alluvial', 'red', 'black', 'loamy'],
      idealSeasons: ['kharif', 'rabi', 'zaid'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 25.0,
      basePricePerQuintal: 2150.0,
      cultivationCostPerAcre: 16000.0,
      riskLevel: 'low',
      agronomicTips: 'Highly versatile crop. Ensure good drainage; avoid water stagnation at early seedling phase.',
    ),
    CropModel(
      id: 'chickpea',
      name: {'en': 'Chickpea (Gram)', 'hi': 'चना', 'mr': 'हरभरा'},
      category: 'pulse',
      growthDurationDays: 105,
      idealSoilTypes: ['black', 'alluvial', 'loamy', 'clay'],
      idealSeasons: ['rabi'],
      waterRequirement: 'low',
      estimatedYieldQuintalPerAcre: 9.0,
      basePricePerQuintal: 5450.0,
      cultivationCostPerAcre: 11000.0,
      riskLevel: 'low',
      agronomicTips: 'Requires minimal water. Ideal pulse for conserving soil nitrogen in rotation with cereals.',
    ),
    CropModel(
      id: 'pigeonpeas',
      name: {'en': 'Pigeon Pea (Tur/Arhar)', 'hi': 'तुअर / अरहर', 'mr': 'तूर'},
      category: 'pulse',
      growthDurationDays: 160,
      idealSoilTypes: ['black', 'red', 'alluvial', 'loamy'],
      idealSeasons: ['kharif'],
      waterRequirement: 'low',
      estimatedYieldQuintalPerAcre: 8.5,
      basePricePerQuintal: 7000.0,
      cultivationCostPerAcre: 13000.0,
      riskLevel: 'medium',
      agronomicTips: 'Deep taproot system tolerates moisture stress. Excellent intercrop with soybean or cotton.',
    ),
    CropModel(
      id: 'sugarcane',
      name: {'en': 'Sugarcane', 'hi': 'गन्ना', 'mr': 'ऊस'},
      category: 'cash crop',
      growthDurationDays: 330,
      idealSoilTypes: ['black', 'alluvial', 'loamy'],
      idealSeasons: ['kharif', 'rabi'],
      waterRequirement: 'high',
      estimatedYieldQuintalPerAcre: 400.0,
      basePricePerQuintal: 315.0,
      cultivationCostPerAcre: 45000.0,
      riskLevel: 'medium',
      agronomicTips: 'High biomass crop. Requires regular irrigation intervals and timely earthing up.',
    ),
    CropModel(
      id: 'onion',
      name: {'en': 'Onion', 'hi': 'प्याज', 'mr': 'कांदा'},
      category: 'vegetable',
      growthDurationDays: 115,
      idealSoilTypes: ['alluvial', 'red', 'black', 'loamy'],
      idealSeasons: ['kharif', 'rabi'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 110.0,
      basePricePerQuintal: 1650.0,
      cultivationCostPerAcre: 38000.0,
      riskLevel: 'medium',
      agronomicTips: 'Maintain shallow soil moisture during bulb enlargement. Stop watering 10 days before harvest.',
    ),
    CropModel(
      id: 'tomato',
      name: {'en': 'Tomato', 'hi': 'टमाटर', 'mr': 'टोमॅटो'},
      category: 'vegetable',
      growthDurationDays: 95,
      idealSoilTypes: ['red', 'alluvial', 'black', 'loamy'],
      idealSeasons: ['kharif', 'rabi', 'zaid'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 140.0,
      basePricePerQuintal: 1400.0,
      cultivationCostPerAcre: 42000.0,
      riskLevel: 'medium',
      agronomicTips: 'Staking supports high fruit yield and reduces soil-borne rot. Monitor for leaf curls and fruit borer.',
    ),
    CropModel(
      id: 'soybean',
      name: {'en': 'Soybean', 'hi': 'सोयाबीन', 'mr': 'सोयाबीन'},
      category: 'pulse',
      growthDurationDays: 95,
      idealSoilTypes: ['black', 'alluvial', 'loamy'],
      idealSeasons: ['kharif'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 11.0,
      basePricePerQuintal: 4600.0,
      cultivationCostPerAcre: 12500.0,
      riskLevel: 'low',
      agronomicTips: 'Major Kharif cash crop in Maharashtra. Treat seeds with Rhizobium before sowing.',
    ),
    CropModel(
      id: 'grapes',
      name: {'en': 'Grapes', 'hi': 'अंगूर', 'mr': 'द्राक्षे'},
      category: 'fruit',
      growthDurationDays: 140,
      idealSoilTypes: ['alluvial', 'red', 'loamy', 'black'],
      idealSeasons: ['rabi'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 90.0,
      basePricePerQuintal: 4500.0,
      cultivationCostPerAcre: 95000.0,
      riskLevel: 'high',
      agronomicTips: 'High-value horticultural crop. Requires canopy management and strict downy mildew control.',
    ),
    CropModel(
      id: 'pomegranate',
      name: {'en': 'Pomegranate', 'hi': 'अनार', 'mr': 'डाळिंब'},
      category: 'fruit',
      growthDurationDays: 180,
      idealSoilTypes: ['loamy', 'alluvial', 'red', 'sandy'],
      idealSeasons: ['kharif', 'rabi'],
      waterRequirement: 'low',
      estimatedYieldQuintalPerAcre: 55.0,
      basePricePerQuintal: 6200.0,
      cultivationCostPerAcre: 60000.0,
      riskLevel: 'medium',
      agronomicTips: 'Drought-hardy fruit crop. Protect against bacterial blight using clean orchard sanitation.',
    ),
    CropModel(
      id: 'watermelon',
      name: {'en': 'Watermelon', 'hi': 'तरबूज', 'mr': 'कलिंगड'},
      category: 'fruit',
      growthDurationDays: 85,
      idealSoilTypes: ['sandy', 'alluvial', 'loamy'],
      idealSeasons: ['zaid'],
      waterRequirement: 'medium',
      estimatedYieldQuintalPerAcre: 160.0,
      basePricePerQuintal: 950.0,
      cultivationCostPerAcre: 28000.0,
      riskLevel: 'low',
      agronomicTips: 'Quick 80-90 day summer crop. Thrives under drip fertigation and plastic mulching.',
    ),
    CropModel(
      id: 'banana',
      name: {'en': 'Banana', 'hi': 'केला', 'mr': 'केळी'},
      category: 'fruit',
      growthDurationDays: 300,
      idealSoilTypes: ['alluvial', 'black', 'clay', 'loamy'],
      idealSeasons: ['kharif', 'rabi'],
      waterRequirement: 'high',
      estimatedYieldQuintalPerAcre: 280.0,
      basePricePerQuintal: 1550.0,
      cultivationCostPerAcre: 75000.0,
      riskLevel: 'medium',
      agronomicTips: 'High feeder crop. Requires intensive drip irrigation and bunch covering for export quality.',
    ),
  ];

  /// Generates recommendations using agronomic scoring with ML fallback.
  static Future<List<CropRecommendationOutput>> getRecommendations(
    RecommendationInput input, {
    String langCode = 'en',
  }) async {
    // Attempt backend model inference if server is reachable
    try {
      final backendResults = await _tryBackendPrediction(input, langCode);
      if (backendResults.isNotEmpty) {
        return backendResults;
      }
    } catch (_) {
      // Backend not running / offline — fallback to robust local agronomic scoring
    }

    return _scoreAgronomicCrops(input, langCode);
  }

  /// Tries calling FastAPI `/recommend_crop` endpoint.
  static Future<List<CropRecommendationOutput>> _tryBackendPrediction(
    RecommendationInput input,
    String langCode,
  ) async {
    final url = Uri.parse('${ApiService.baseUrl}/recommend_crop');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(input.toMap()),
        )
        .timeout(const Duration(seconds: 2));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['recommendations'] is List) {
        return (data['recommendations'] as List)
            .map((e) => CropRecommendationOutput.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  }

  /// Comprehensive Agronomic Decision and Scoring Engine.
  static List<CropRecommendationOutput> _scoreAgronomicCrops(
    RecommendationInput input,
    String langCode,
  ) {
    final List<MapEntry<CropModel, double>> scoredCrops = [];

    for (final crop in cropCatalog) {
      double score = 100.0;

      // 1. Soil Compatibility (Weight: 35%)
      final normSoil = input.soilType.toLowerCase();
      if (crop.idealSoilTypes.contains(normSoil)) {
        score += 15.0;
      } else if (normSoil == 'black' && crop.idealSoilTypes.contains('clay')) {
        score += 5.0;
      } else if (normSoil == 'sandy' && crop.waterRequirement == 'high') {
        score -= 40.0; // Sandy soil dries too fast for high-water crops
      } else {
        score -= 25.0;
      }

      // 2. Seasonal Alignment (Weight: 35%)
      final normSeason = input.season.toLowerCase();
      if (crop.idealSeasons.contains(normSeason)) {
        score += 20.0;
      } else {
        score -= 50.0; // Out of season penalty
      }

      // 3. Water Availability Match (Weight: 25%)
      final normWater = input.waterAvailability.toLowerCase();
      if (normWater == crop.waterRequirement) {
        score += 10.0;
      } else if (normWater == 'low' && crop.waterRequirement == 'high') {
        score -= 60.0; // Severe drought risk
      } else if (normWater == 'high' && crop.waterRequirement == 'low') {
        score -= 10.0; // Excess water for low-water crops like chickpea
      }

      // 4. Soil pH adjustment if provided
      if (input.ph != null) {
        if (input.ph! >= 6.0 && input.ph! <= 7.5) {
          score += 5.0;
        } else {
          score -= 10.0;
        }
      }

      if (score > 35) {
        scoredCrops.add(MapEntry(crop, score));
      }
    }

    // Sort by computed suitability score descending
    scoredCrops.sort((a, b) => b.value.compareTo(a.value));

    // Convert top candidates to CropRecommendationOutput
    final topList = scoredCrops.take(5).map((entry) {
      final crop = entry.key;
      final rawScore = entry.value.clamp(45.0, 98.0);
      final suitability = rawScore.round();
      final confidence = (suitability / 100.0);

      final yieldPerAcre = crop.estimatedYieldQuintalPerAcre * (input.farmSizeAcres > 0 ? input.farmSizeAcres : 1.0);
      final revenue = yieldPerAcre * crop.basePricePerQuintal;
      final cost = crop.cultivationCostPerAcre * (input.farmSizeAcres > 0 ? input.farmSizeAcres : 1.0);
      final profit = revenue - cost;

      String sowingWindow;
      switch (input.season.toLowerCase()) {
        case 'rabi':
          sowingWindow = 'October - December';
          break;
        case 'zaid':
          sowingWindow = 'February - April';
          break;
        case 'kharif':
        default:
          sowingWindow = 'June - July';
          break;
      }

      return CropRecommendationOutput(
        cropId: crop.id,
        cropName: crop.getLocalizedName(langCode),
        estimatedProfit: profit,
        waterRequirement: crop.waterRequirement,
        riskLevel: crop.riskLevel,
        confidenceScore: confidence,
        suitabilityScore: suitability,
        growthDurationDays: crop.growthDurationDays,
        sowingWindow: sowingWindow,
        agronomicTips: crop.agronomicTips ?? 'Ensure balanced NPK fertilization and timely weeding.',
        estimatedYieldQuintal: yieldPerAcre,
        estimatedRevenue: revenue,
        estimatedCost: cost,
      );
    }).toList();

    return topList;
  }

  /// Saves generated recommendation results to Firestore `recommendations` collection.
  static Future<void> saveRecommendationRecord({
    required String farmerId,
    required RecommendationInput input,
    required List<CropRecommendationOutput> outputs,
  }) async {
    try {
      final docRef = FirestoreRefs.recommendations.doc();
      final record = RecommendationRecord(
        id: docRef.id,
        farmerId: farmerId,
        input: input,
        output: outputs,
        createdAt: DateTime.now(),
      );

      await docRef.set(record.toMap());
    } catch (_) {
      // Ignore / log error if network is offline
    }
  }

  /// Streams past recommendation history for the current farmer.
  static Stream<List<RecommendationRecord>> streamHistory(String farmerId) {
    return FirestoreRefs.recommendations
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RecommendationRecord.fromMap(
          doc.id,
          Map<String, dynamic>.from(doc.data() as Map),
        );
      }).toList();
    });
  }
}
