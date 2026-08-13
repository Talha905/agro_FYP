import 'api_service.dart';

class DiseaseDetectorService {
  /// Runs disease prediction on an image file by sending it to the
  /// FastAPI backend server for inference using the plant disease model.
  Future<Map<String, dynamic>> predict(String imagePath) async {
    try {
      print('DiseaseDetectorService: Sending image to FastAPI backend...');

      final apiResult = await ApiService.predictDisease(imagePath);

      final bool success = apiResult['success'] ?? false;

      if (!success) {
        final errorMsg = apiResult['error'] ?? 'Inference failed on the server.';
        return {
          'success': false,
          'source': 'api',
          'disease': 'Detection Failed',
          'confidence': 0.0,
          'error': errorMsg,
        };
      }

      // Backend returns confidence already scaled as a percentage (e.g. 98.5).
      // Normalize it to 0.0 — 1.0 for the UI confidence bar.
      double confidence = 0.0;
      if (apiResult['confidence'] != null) {
        confidence = (apiResult['confidence'] as num).toDouble() / 100.0;
      }

      print('DiseaseDetectorService: Prediction complete → ${apiResult['disease']}');

      return {
        'success': true,
        'source': 'api',
        'disease': apiResult['disease'] ?? 'Unknown',
        'confidence': confidence,
      };
    } catch (e) {
      print('DiseaseDetectorService: FastAPI prediction failed: $e');
      return {
        'success': false,
        'source': 'api',
        'disease': 'Detection Failed',
        'confidence': 0.0,
        'error': 'Could not connect to the backend server. Please ensure the FastAPI server is running.\nDetails: $e',
      };
    }
  }
}
