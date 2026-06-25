import 'package:flutter/material.dart';

class DiseaseDetectorScreen
    extends StatelessWidget {

  const DiseaseDetectorScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return const Center(
      child: Text(
        "Disease Detector Module",
        style: TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}