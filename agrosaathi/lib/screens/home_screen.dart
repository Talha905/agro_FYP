import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return ListView(
      padding:
          const EdgeInsets.all(16),

      children: [

        Card(
          child: ListTile(
            leading:
                const Icon(Icons.cloud),
            title:
                const Text("Weather"),
            subtitle: const Text(
              "Weather data will appear here",
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading:
                const Icon(Icons.timeline),
            title:
                const Text("Growth Planner"),
            subtitle: const Text(
              "Track crop growth stages",
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading:
                const Icon(Icons.lightbulb),
            title: const Text(
              "Recommendations",
            ),
            subtitle: const Text(
              "Personalized farming advice",
            ),
          ),
        ),
      ],
    );
  }
}