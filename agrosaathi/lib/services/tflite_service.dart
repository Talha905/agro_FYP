import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfliteService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> _loadModelAndLabels() async {
    if (_interpreter != null && _labels != null) return;
    try {
      // Load interpreter from assets
      _interpreter = await Interpreter.fromAsset('assets/model/plant_disease_model.tflite');
      
      // Load labels from assets
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      print('TfliteService: Error loading model/labels: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
    await _loadModelAndLabels();
    
    if (_interpreter == null || _labels == null) {
      throw Exception('TFLite Model or Labels not loaded properly.');
    }

    // 1. Read and decode the image file
    final fileBytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(fileBytes);
    if (decodedImage == null) {
      throw Exception('Could not decode image at path: $imagePath');
    }

    // 2. Preprocess: Resize to 256x256
    final resizedImage = img.copyResize(decodedImage, width: 256, height: 256);

    // 3. Convert to input tensor [1, 256, 256, 3] with floats normalized to [0, 1]
    final input = List.generate(
      1,
      (i) => List.generate(
        256,
        (y) => List.generate(
          256,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r.toDouble() / 255.0,
              pixel.g.toDouble() / 255.0,
              pixel.b.toDouble() / 255.0,
            ];
          },
        ),
      ),
    );

    // 4. Output tensor: [1, number of classes]
    int numClasses = _labels!.length;
    try {
      final outputTensors = _interpreter!.getOutputTensors();
      if (outputTensors.isNotEmpty && outputTensors[0].shape.length > 1) {
        numClasses = outputTensors[0].shape[1];
      }
    } catch (e) {
      print('TfliteService: Failed to fetch output shape, using labels count: $e');
    }

    var output = List.generate(1, (i) => List<double>.filled(numClasses, 0.0));

    // 5. Run inference
    _interpreter!.run(input, output);

    // 6. Post-process: find class with highest confidence
    final probabilities = output[0];
    int bestIndex = 0;
    double maxProb = -1.0;
    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        bestIndex = i;
      }
    }

    final String disease = (bestIndex < _labels!.length) ? _labels![bestIndex] : 'Unknown';

    return {
      'disease': disease,
      'confidence': maxProb,
    };
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
