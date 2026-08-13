import 'tflite_service.dart';
import 'api_service.dart';

class DiseaseDetectorService {
  final TfliteService _tfliteService = TfliteService();

  /// Runs disease prediction on an image file.
  /// 
  /// Attempts on-device classification using TensorFlow Lite first. If this 
  /// encounters any error (e.g. unsupported platform, dynamic library missing,
  /// or out of memory), it will fall back to using the FastAPI backend service.
  Future<Map<String, dynamic>> predict(String imagePath) async {
    try {
      print('DiseaseDetectorService: Trying local prediction...');
      final localResult = await _tfliteService.predict(imagePath);
      print('DiseaseDetectorService: Local prediction successful.');
      return {
        'success': true,
        'source': 'local',
        'disease': localResult['disease'],
        'confidence': localResult['confidence'] ?? 0.0,
      };
    } catch (localError) {
      print('DiseaseDetectorService: Local prediction failed: $localError');
      print('DiseaseDetectorService: Falling back to API prediction...');
      try {
        final apiResult = await ApiService.predictDisease(imagePath);
        print('DiseaseDetectorService: API prediction complete.');

        final bool success = apiResult['success'] ?? false;
        if (!success) {
          final errorMsg = apiResult['error'] ?? 'Inference failed on server';
          throw Exception(errorMsg);
        }

        // The backend API returns confidence scaled as percentages (e.g. 98.5).
        // We normalize it to a 0.0 to 1.0 scale to remain consistent with TFLite output.
        double confidence = 0.0;
        if (apiResult['confidence'] != null) {
          confidence = (apiResult['confidence'] as num).toDouble() / 100.0;
        }

        return {
          'success': true,
          'source': 'api',
          'disease': apiResult['disease'] ?? 'Unknown',
          'confidence': confidence,
        };
      } catch (apiError) {
        print('DiseaseDetectorService: Remote API prediction failed: $apiError');
        return {
          'success': false,
          'source': 'failed',
          'error': 'Local error: $localError. Server error: $apiError',
          'disease': 'Detection Failed',
          'confidence': 0.0,
        };
      }
    }
  }

  void dispose() {
    _tfliteService.dispose();
  }
}
