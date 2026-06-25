import 'package:flutter/material.dart';

class CropAdvisorScreen
    extends StatelessWidget {

  const CropAdvisorScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return const Center(
      child: Text(
        "Crop Advisor Module",
        style: TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}