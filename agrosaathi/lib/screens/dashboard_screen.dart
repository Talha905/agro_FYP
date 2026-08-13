import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'crop_advisor_screen.dart';
import 'disease_detector_screen.dart';
import 'marketplace_screen.dart';
import 'profile_screen.dart';
import '../services/growth_plan_service.dart';
import '../services/user_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: bring any active growth plan's currentStage up to
    // date with elapsed days since planting. HomeScreen's stream will pick
    // up any resulting Firestore writes automatically.
    final farmerId = UserService.currentUser?.uid;
    if (farmerId != null) {
      GrowthPlanService().syncStagesForFarmer(farmerId).catchError((_) {
        // Non-critical — a stale stage label is not worth surfacing an error for.
      });
    }
  }

  final List<Widget> screens = const [
    HomeScreen(),
    CropAdvisorScreen(),
    DiseaseDetectorScreen(),
    MarketplaceScreen(),
    ProfileScreen(),
  ];

  final List<String> titles = [
    "Home",
    "Crop Advisor",
    "Disease Detector",
    "Marketplace",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
        ),
        centerTitle: true,
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            selectedIndex,

        onDestinationSelected:
            (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: "Advisor",
          ),

          NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: "Disease",
          ),

          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: "Market",
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}