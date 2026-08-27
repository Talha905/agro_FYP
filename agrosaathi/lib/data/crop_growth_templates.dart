/// Static lifecycle templates for supported crops.
/// Per the design doc: "store these as a static Dart map ... or as Firestore
/// documents under crop_templates/{cropName}". We start static (faster, no
/// extra reads) and can migrate to Firestore later without touching any
/// screen code, since screens only ever talk to CropTemplates / GrowthPlanGenerator.
///
/// Stage names are intentionally restricted to the enum used in the
/// Firestore schema doc for `growthPlans.currentStage`:
///   sowing | germination | vegetative | flowering | maturity | harvested
/// ("harvested" is a terminal status set manually, not a timed stage.)
library;

class GrowthStage {
  final String name;
  final int durationDays;
  final int irrigationFrequencyDays;
  final List<String> pestRisks;

  const GrowthStage({
    required this.name,
    required this.durationDays,
    required this.irrigationFrequencyDays,
    this.pestRisks = const [],
  });
}

class FertilizerStep {
  final String stageName;
  final String fertilizerType;
  final int dayOffsetInStage; // applied this many days after the stage starts

  const FertilizerStep({
    required this.stageName,
    required this.fertilizerType,
    required this.dayOffsetInStage,
  });
}

class CropGrowthTemplate {
  final String cropSlug; // local id (e.g. "wheat") — see integration note in service file
  final String displayName;
  final List<GrowthStage> stages;
  final List<FertilizerStep> fertilizerPlan;

  const CropGrowthTemplate({
    required this.cropSlug,
    required this.displayName,
    required this.stages,
    required this.fertilizerPlan,
  });

  int get totalDurationDays => stages.fold(0, (sum, s) => sum + s.durationDays);
}

class CropTemplates {
  static const wheat = CropGrowthTemplate(
    cropSlug: 'wheat',
    displayName: 'Wheat',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 7, irrigationFrequencyDays: 10),
      GrowthStage(name: 'germination', durationDays: 10, irrigationFrequencyDays: 8, pestRisks: ['Termites']),
      GrowthStage(name: 'vegetative', durationDays: 45, irrigationFrequencyDays: 12, pestRisks: ['Aphids']),
      GrowthStage(name: 'flowering', durationDays: 25, irrigationFrequencyDays: 10, pestRisks: ['Rust disease']),
      GrowthStage(name: 'maturity', durationDays: 20, irrigationFrequencyDays: 15),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal DAP + Urea', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 20),
    ],
  );

  static const rice = CropGrowthTemplate(
    cropSlug: 'rice',
    displayName: 'Rice',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 10, irrigationFrequencyDays: 1),
      GrowthStage(name: 'germination', durationDays: 10, irrigationFrequencyDays: 2, pestRisks: ['Stem borer']),
      GrowthStage(name: 'vegetative', durationDays: 35, irrigationFrequencyDays: 3, pestRisks: ['Leaf folder']),
      GrowthStage(name: 'flowering', durationDays: 25, irrigationFrequencyDays: 3, pestRisks: ['Blast disease']),
      GrowthStage(name: 'maturity', durationDays: 25, irrigationFrequencyDays: 7),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal NPK', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 15),
      FertilizerStep(stageName: 'flowering', fertilizerType: 'Potash', dayOffsetInStage: 5),
    ],
  );

  static const cotton = CropGrowthTemplate(
    cropSlug: 'cotton',
    displayName: 'Cotton',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 10, irrigationFrequencyDays: 10),
      GrowthStage(name: 'germination', durationDays: 15, irrigationFrequencyDays: 10, pestRisks: ['Cutworm']),
      GrowthStage(name: 'vegetative', durationDays: 50, irrigationFrequencyDays: 12, pestRisks: ['Whitefly']),
      GrowthStage(name: 'flowering', durationDays: 60, irrigationFrequencyDays: 10, pestRisks: ['Bollworm']),
      GrowthStage(name: 'maturity', durationDays: 45, irrigationFrequencyDays: 15),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal NPK', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 25),
      FertilizerStep(stageName: 'flowering', fertilizerType: 'Potash + micronutrients', dayOffsetInStage: 10),
    ],
  );

  static const sugarcane = CropGrowthTemplate(
    cropSlug: 'sugarcane',
    displayName: 'Sugarcane',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 15, irrigationFrequencyDays: 8),
      GrowthStage(name: 'germination', durationDays: 30, irrigationFrequencyDays: 7, pestRisks: ['Early shoot borer']),
      GrowthStage(name: 'vegetative', durationDays: 150, irrigationFrequencyDays: 10, pestRisks: ['Top borer']),
      GrowthStage(name: 'flowering', durationDays: 60, irrigationFrequencyDays: 12),
      GrowthStage(name: 'maturity', durationDays: 75, irrigationFrequencyDays: 20),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal NPK', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'germination', fertilizerType: 'Urea', dayOffsetInStage: 20),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea + Potash split dose', dayOffsetInStage: 60),
    ],
  );

  static const tomato = CropGrowthTemplate(
    cropSlug: 'tomato',
    displayName: 'Tomato',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 10, irrigationFrequencyDays: 3),
      GrowthStage(name: 'germination', durationDays: 10, irrigationFrequencyDays: 4, pestRisks: ['Damping off']),
      GrowthStage(name: 'vegetative', durationDays: 25, irrigationFrequencyDays: 5, pestRisks: ['Aphids']),
      GrowthStage(name: 'flowering', durationDays: 30, irrigationFrequencyDays: 5, pestRisks: ['Fruit borer']),
      GrowthStage(name: 'maturity', durationDays: 25, irrigationFrequencyDays: 6),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Compost + basal NPK', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 10),
      FertilizerStep(stageName: 'flowering', fertilizerType: 'Potash', dayOffsetInStage: 5),
    ],
  );

  static const onion = CropGrowthTemplate(
    cropSlug: 'onion',
    displayName: 'Onion',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 25, irrigationFrequencyDays: 4),
      GrowthStage(name: 'germination', durationDays: 10, irrigationFrequencyDays: 5),
      GrowthStage(name: 'vegetative', durationDays: 40, irrigationFrequencyDays: 7, pestRisks: ['Thrips']),
      GrowthStage(name: 'flowering', durationDays: 20, irrigationFrequencyDays: 8),
      GrowthStage(name: 'maturity', durationDays: 25, irrigationFrequencyDays: 10, pestRisks: ['Purple blotch']),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal NPK', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 15),
    ],
  );

  static const potato = CropGrowthTemplate(
    cropSlug: 'potato',
    displayName: 'Potato',
    stages: [
      GrowthStage(name: 'sowing', durationDays: 10, irrigationFrequencyDays: 6),
      GrowthStage(name: 'germination', durationDays: 15, irrigationFrequencyDays: 6, pestRisks: ['Cutworm']),
      GrowthStage(name: 'vegetative', durationDays: 30, irrigationFrequencyDays: 7, pestRisks: ['Aphids']),
      GrowthStage(name: 'flowering', durationDays: 25, irrigationFrequencyDays: 8, pestRisks: ['Late blight']),
      GrowthStage(name: 'maturity', durationDays: 20, irrigationFrequencyDays: 10),
    ],
    fertilizerPlan: [
      FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal NPK', dayOffsetInStage: 0),
      FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 15),
    ],
  );

  static const List<CropGrowthTemplate> all = [
    wheat,
    rice,
    cotton,
    sugarcane,
    tomato,
    onion,
    potato,
  ];

  static CropGrowthTemplate generic(String displayName) {
    final slug = displayName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return CropGrowthTemplate(
      cropSlug: slug.isEmpty ? 'custom_crop' : slug,
      displayName: displayName.isEmpty ? 'Custom Crop' : displayName,
      stages: const [
        GrowthStage(name: 'sowing', durationDays: 10, irrigationFrequencyDays: 5),
        GrowthStage(name: 'germination', durationDays: 12, irrigationFrequencyDays: 6, pestRisks: ['General Pests']),
        GrowthStage(name: 'vegetative', durationDays: 35, irrigationFrequencyDays: 7, pestRisks: ['Leaf Spot']),
        GrowthStage(name: 'flowering', durationDays: 30, irrigationFrequencyDays: 7, pestRisks: ['Blight']),
        GrowthStage(name: 'maturity', durationDays: 25, irrigationFrequencyDays: 10),
      ],
      fertilizerPlan: const [
        FertilizerStep(stageName: 'sowing', fertilizerType: 'Basal NPK', dayOffsetInStage: 0),
        FertilizerStep(stageName: 'vegetative', fertilizerType: 'Urea top dressing', dayOffsetInStage: 15),
      ],
    );
  }
}
