import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/disease_detector_service.dart';

class DiseaseDetectorScreen extends StatefulWidget {
  const DiseaseDetectorScreen({super.key});

  @override
  State<DiseaseDetectorScreen> createState() => _DiseaseDetectorScreenState();
}

class _DiseaseDetectorScreenState extends State<DiseaseDetectorScreen> {
  final DiseaseDetectorService _detectorService = DiseaseDetectorService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _predictionResult = null;
        });
        _runPrediction();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _runPrediction() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      final result = await _detectorService.predict(_imageFile!.path);
      if (!mounted) return;
      setState(() => _predictionResult = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Converts a raw model label (e.g. "Tomato___Early_blight") into a
  /// human-readable string (e.g. "Tomato: Early Blight").
  String _formatDisease(String rawLabel) {
    final parts = rawLabel.split('___');
    if (parts.length < 2) return rawLabel.replaceAll('_', ' ');
    final crop = parts[0].replaceAll('_', ' ').trim();
    final disease = parts[1].replaceAll('_', ' ').trim();
    return disease.toLowerCase() == 'healthy' ? '$crop (Healthy)' : '$crop: $disease';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Info Card ──────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            color: cs.surfaceVariant.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.spa, size: 40, color: cs.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Disease Detector',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capture or upload a crop leaf photo. Our FastAPI server will classify the disease instantly.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Image Preview ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _showImageSourceSelector(context),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _imageFile != null
                      ? cs.primary.withOpacity(0.5)
                      : cs.outlineVariant,
                  width: 2,
                ),
                boxShadow: _imageFile != null
                    ? [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to Change',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 64,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to Add Plant Image',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supports JPG, PNG',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Picker Buttons ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Loading State ────────────────────────────────────────────────
          if (_isLoading)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing image...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sending to FastAPI backend for classification',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // ── Result Card ──────────────────────────────────────────────────
          if (_predictionResult != null)
            _buildResultCard(context, cs, theme),
        ],
      ),
    );
  }

  void _showImageSourceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ColorScheme cs, ThemeData theme) {
    final bool success = _predictionResult!['success'] ?? false;

    // ── Error State ────────────────────────────────────────────────────────
    if (!success) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.error.withOpacity(0.5)),
        ),
        color: cs.errorContainer.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_off, color: cs.error),
                  const SizedBox(width: 8),
                  Text(
                    'Server Unreachable',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _predictionResult!['error'] ??
                    'An unknown error occurred. Please ensure the FastAPI backend is running.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Success State ──────────────────────────────────────────────────────
    final String rawDisease = _predictionResult!['disease'] ?? 'Unknown';
    final double confidence = _predictionResult!['confidence'] ?? 0.0;
    final String formattedName = _formatDisease(rawDisease);
    final bool isHealthy = rawDisease.toLowerCase().contains('healthy');
    final Color resultColor = isHealthy ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: resultColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isHealthy ? Icons.check_circle : Icons.warning,
                      color: resultColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHealthy ? 'Healthy Plant' : 'Disease Detected',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: resultColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Source Badge — always FastAPI
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'FastAPI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Confidence Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confidence Score',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(confidence * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 8,
                    backgroundColor: cs.primary.withOpacity(0.15),
                    color: cs.primary,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isHealthy
                            ? 'Keep up regular watering and soil nutrient checks.'
                            : 'Visit the Crop Advisor tab for detailed treatment recommendations.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}