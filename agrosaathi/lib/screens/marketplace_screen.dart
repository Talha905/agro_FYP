import 'package:flutter/material.dart';

class MarketplaceScreen
    extends StatelessWidget {

  const MarketplaceScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return const Center(
      child: Text(
        "Marketplace Module",
        style: TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}