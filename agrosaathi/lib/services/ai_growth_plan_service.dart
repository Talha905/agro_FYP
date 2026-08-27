import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/crop_growth_templates.dart';

/// Calls the FastAPI backend's /generate-growth-plan endpoint (Claude-powered)
/// to build a CropGrowthTemplate for any crop name the farmer types in.
///
/// IMPORTANT: never call an AI API's key directly from this Flutter app —
/// the backend holds the key server-side. This service only ever talks to
/// our own backend.
class AIGrowthPlanService {
  // TODO: point this at your deployed backend before release.
  // For local testing against `uvicorn app:app --reload`, Android emulator
  // reaches your host machine's localhost via 10.0.2.2, not 127.0.0.1.
  static const String _baseUrl = 'http://10.0.2.2:8000';

  /// Returns a CropGrowthTemplate on success, or throws on any failure
  /// (network error, timeout, or the backend reporting success:false).
  /// Callers should catch and fall back to a static CropTemplates entry.
  static Future<CropGrowthTemplate> generate({
    required String cropName,
    String? soilType,
    String? season,
    String? region,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/generate-growth-plan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cropName': cropName,
            if (soilType != null) 'soilType': soilType,
            if (season != null) 'season': season,
            if (region != null) 'region': region,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'AI generation failed');
    }

    return _parseTemplate(body['template'] as Map<String, dynamic>);
  }

  static CropGrowthTemplate _parseTemplate(Map<String, dynamic> json) {
    final stages = (json['stages'] as List)
        .map((s) => GrowthStage(
              name: s['name'],
              durationDays: s['durationDays'],
              irrigationFrequencyDays: s['irrigationFrequencyDays'],
              pestRisks: List<String>.from(s['pestRisks'] ?? []),
            ))
        .toList();

    final fertilizerPlan = (json['fertilizerPlan'] as List? ?? [])
        .map((f) => FertilizerStep(
              stageName: f['stageName'],
              fertilizerType: f['fertilizerType'],
              dayOffsetInStage: f['dayOffsetInStage'],
            ))
        .toList();

    final cropName = json['cropName'] as String;

    return CropGrowthTemplate(
      cropSlug: _slugify(cropName),
      displayName: cropName,
      stages: stages,
      fertilizerPlan: fertilizerPlan,
    );
  }

  static String _slugify(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}
