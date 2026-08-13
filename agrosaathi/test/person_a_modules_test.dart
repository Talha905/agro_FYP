import 'package:flutter_test/flutter_test.dart';
import 'package:agrosaathi/models/crop_model.dart';
import 'package:agrosaathi/models/recommendation_model.dart';
import 'package:agrosaathi/models/weather_model.dart';
import 'package:agrosaathi/services/crop_recommendation_service.dart';
import 'package:agrosaathi/services/localization_service.dart';

void main() {
  group('Person A — Localization Service Tests', () {
    test('Translates keys across English, Hindi, and Marathi', () {
      LocalizationService.setLocale('en');
      expect(LocalizationService.tr('nav_home'), 'Home');
      expect(LocalizationService.tr('crop_recommendations'), 'Crop Recommender');

      LocalizationService.setLocale('hi');
      expect(LocalizationService.tr('nav_home'), 'मुख्य पृष्ठ');
      expect(LocalizationService.tr('crop_recommendations'), 'फसल अनुशंसा');

      LocalizationService.setLocale('mr');
      expect(LocalizationService.tr('nav_home'), 'मुख्यपृष्ठ');
      expect(LocalizationService.tr('crop_recommendations'), 'पीक शिफारस');
    });
  });

  group('Person A — Crop Recommendation Engine Tests', () {
    test('Recommends Rabi crops (Wheat/Chickpea) for Rabi season & Black soil', () async {
      final input = RecommendationInput(
        soilType: 'black',
        season: 'rabi',
        waterAvailability: 'medium',
        district: 'Nashik, Maharashtra',
        farmSizeAcres: 2.0,
      );

      final recommendations = await CropRecommendationService.getRecommendations(input, langCode: 'en');

      expect(recommendations.isNotEmpty, true);
      final cropIds = recommendations.map((r) => r.cropId).toList();
      expect(cropIds.contains('wheat') || cropIds.contains('chickpea'), true);

      final topCrop = recommendations.first;
      expect(topCrop.suitabilityScore, greaterThanOrEqualTo(70));
      expect(topCrop.estimatedProfit, greaterThan(0));
      expect(topCrop.agronomicTips.isNotEmpty, true);
    });

    test('Recommends Kharif crops (Rice/Cotton/Soybean) for Kharif season', () async {
      final input = RecommendationInput(
        soilType: 'alluvial',
        season: 'kharif',
        waterAvailability: 'high',
        district: 'Kolhapur, Maharashtra',
        farmSizeAcres: 3.0,
      );

      final recommendations = await CropRecommendationService.getRecommendations(input, langCode: 'mr');

      expect(recommendations.isNotEmpty, true);
      final firstResult = recommendations.first;
      expect(firstResult.estimatedYieldQuintal, greaterThan(0));
      expect(firstResult.estimatedRevenue, greaterThan(firstResult.estimatedCost));
    });
  });

  group('Person A — Data Models Serialization Tests', () {
    test('CropModel toMap and fromMap match schema', () {
      final crop = CropModel(
        id: 'cotton',
        name: {'en': 'Cotton', 'hi': 'कपास', 'mr': 'कापूस'},
        category: 'cash crop',
        growthDurationDays: 165,
        idealSoilTypes: ['black', 'alluvial'],
        idealSeasons: ['kharif'],
        waterRequirement: 'medium',
        estimatedYieldQuintalPerAcre: 10.5,
        basePricePerQuintal: 7120.0,
        cultivationCostPerAcre: 24000.0,
        riskLevel: 'medium',
      );

      final map = crop.toMap();
      final restored = CropModel.fromMap('cotton', map);

      expect(restored.id, 'cotton');
      expect(restored.name['hi'], 'कपास');
      expect(restored.growthDurationDays, 165);
      expect(restored.basePricePerQuintal, 7120.0);
    });

    test('WeatherInfo generates agricultural advisories from weather conditions', () {
      final rainyJson = {
        'name': 'Kolhapur',
        'main': {'temp': 26.0, 'humidity': 85},
        'weather': [
          {'main': 'Rain', 'description': 'moderate rain'}
        ],
        'wind': {'speed': 4.5},
        'clouds': {'all': 90},
      };

      final weather = WeatherInfo.fromJson(rainyJson);
      expect(weather.isRainExpected, true);
      expect(weather.agriculturalAdvisory.contains('Rain anticipated'), true);
      expect(weather.temperature, 26.0);
      expect(weather.humidity, 85);
    });
  });
}
