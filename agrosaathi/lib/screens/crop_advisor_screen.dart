import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../models/recommendation_model.dart';
import '../services/crop_recommendation_service.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';
import '../services/soil_grids_service.dart';
import '../services/community_preset_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import 'recommendation_result_screen.dart';

import '../services/app_location_provider.dart';

/// Complete Crop Advisor Module Screen.
/// Owned by Person A. Multi-language enabled and responsive.
class CropAdvisorScreen extends StatefulWidget {
  const CropAdvisorScreen({super.key});

  @override
  State<CropAdvisorScreen> createState() => _CropAdvisorScreenState();
}

class _CropAdvisorScreenState extends State<CropAdvisorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();

  String _selectedSoil = 'black';
  String _selectedSeason = 'kharif';
  String _selectedWater = 'medium';
  String _selectedDistrict = 'Pune, Maharashtra';

  final TextEditingController _farmSizeController = TextEditingController(text: '2.0');
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _phController = TextEditingController();

  bool _isLoading = false;
  bool _showAdvancedNpk = false;
  List<CommunityPreset> _communityPresets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Determine current season automatically by month
    final month = DateTime.now().month;
    if (month >= 6 && month <= 10) {
      _selectedSeason = 'kharif';
    } else if (month >= 11 || month <= 3) {
      _selectedSeason = 'rabi';
    } else {
      _selectedSeason = 'zaid';
    }

    // Auto-populate default farm specs if present in UserModel
    final farmDetails = UserService.currentUser?.farmDetails;
    if (farmDetails != null) {
      if (farmDetails['defaultSoilType'] != null) {
        _selectedSoil = farmDetails['defaultSoilType'].toString().toLowerCase();
      }
      if (farmDetails['defaultWaterAvailability'] != null) {
        _selectedWater = farmDetails['defaultWaterAvailability'].toString().toLowerCase();
      }
      if (farmDetails['farmSizeAcres'] != null) {
        _farmSizeController.text = farmDetails['farmSizeAcres'].toString();
      }
    }

    // Seed default NPK for initial soil
    _updateSoilBaselineNpk(_selectedSoil);

    // Listen to shared AppLocationProvider
    AppLocationProvider.stateNotifier.addListener(_onLocationStateChanged);
    _onLocationStateChanged();
  }

  void _onLocationStateChanged() {
    final locState = AppLocationProvider.currentState;
    if (locState.location != null && mounted) {
      setState(() {
        _selectedDistrict = locState.location!.formattedLocation;
      });
      if (locState.soil != null) {
        setState(() {
          _selectedSoil = locState.soil!.soilType;
          _updateSoilBaselineNpk(_selectedSoil);
        });
      }
      _fetchPresetsForDistrict(_selectedDistrict);
    }
  }

  void _updateSoilBaselineNpk(String soilType) {
    final baselines = {
      'black': {'n': '90', 'p': '45', 'k': '50', 'ph': '7.4'},
      'alluvial': {'n': '75', 'p': '35', 'k': '40', 'ph': '6.8'},
      'red': {'n': '60', 'p': '30', 'k': '35', 'ph': '5.8'},
      'sandy': {'n': '50', 'p': '25', 'k': '30', 'ph': '6.5'},
      'clay': {'n': '85', 'p': '40', 'k': '45', 'ph': '7.1'},
      'loamy': {'n': '70', 'p': '35', 'k': '40', 'ph': '6.6'},
    };
    final base = baselines[soilType.toLowerCase()] ?? baselines['black']!;
    if (_nitrogenController.text.isEmpty) _nitrogenController.text = base['n']!;
    if (_phosphorusController.text.isEmpty) _phosphorusController.text = base['p']!;
    if (_potassiumController.text.isEmpty) _potassiumController.text = base['k']!;
    if (_phController.text.isEmpty) _phController.text = base['ph']!;
  }

  Future<void> _fetchPresetsForDistrict(String district) async {
    final presets = await CommunityPresetService.fetchTopCommunityPresets(district);
    if (mounted) {
      setState(() {
        _communityPresets = presets;
      });
    }
  }

  @override
  void dispose() {
    AppLocationProvider.stateNotifier.removeListener(_onLocationStateChanged);
    _tabController.dispose();
    _farmSizeController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _phController.dispose();
    super.dispose();
  }

  void _applyCommunityPreset(CommunityPreset p) {
    setState(() {
      _selectedSoil = p.soilType;
      _selectedSeason = p.season;
      _selectedWater = p.waterAvailability;
      _farmSizeController.text = p.farmSizeAcres.toString();
      if (p.nitrogen != null) _nitrogenController.text = p.nitrogen!.toStringAsFixed(0);
      if (p.phosphorus != null) _phosphorusController.text = p.phosphorus!.toStringAsFixed(0);
      if (p.potassium != null) _potassiumController.text = p.potassium!.toStringAsFixed(0);
      if (p.ph != null) _phController.text = p.ph!.toStringAsFixed(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied community preset for ${p.district} (${p.usefulVotes} 👍 votes)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitRecommendation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final acres = double.tryParse(_farmSizeController.text.trim()) ?? 1.0;
      final n = double.tryParse(_nitrogenController.text.trim());
      final p = double.tryParse(_phosphorusController.text.trim());
      final k = double.tryParse(_potassiumController.text.trim());
      final ph = double.tryParse(_phController.text.trim());

      final input = RecommendationInput(
        soilType: _selectedSoil,
        season: _selectedSeason,
        waterAvailability: _selectedWater,
        district: _selectedDistrict,
        farmSizeAcres: acres,
        nitrogen: n,
        phosphorus: p,
        potassium: k,
        ph: ph,
      );

      final lang = LocalizationService.currentLocale.value;
      final results = await CropRecommendationService.getRecommendations(input, langCode: lang);

      // Save to Firestore in background
      final farmerId = UserService.currentUser?.uid ?? 'guest_farmer';
      CropRecommendationService.saveRecommendationRecord(
        farmerId: farmerId,
        input: input,
        outputs: results,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationResultScreen(
            input: input,
            results: results,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating recommendations: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, langCode, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LocalizationService.tr('advisor_title')),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.psychology_outlined, size: 18),
                  text: LocalizationService.tr('advisor_tab_form'),
                ),
                Tab(
                  icon: const Icon(Icons.history_outlined, size: 18),
                  text: LocalizationService.tr('advisor_tab_history'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFormTab(langCode),
              _buildHistoryTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormTab(String langCode) {
    final locState = AppLocationProvider.currentState;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Location Status Banner & Explicit Error Handling
            if (locState.status == LocationStatus.detecting)
              AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: AppColors.surface,
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fetching live location & soil data via Open-Meteo & SoilGrids...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else if (locState.status == LocationStatus.error || locState.errorMessage != null)
              AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: const Color(0xFFFFEBEE),
                borderColor: AppColors.danger.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            locState.errorMessage ?? 'GPS Location unavailable.',
                            style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (locState.errorType == LocationErrorType.serviceDisabled)
                          TextButton.icon(
                            onPressed: () => LocationService.openLocationSettings(),
                            icon: const Icon(Icons.location_off, size: 14, color: AppColors.danger),
                            label: const Text('Turn On Location Services', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                          )
                        else if (locState.errorType == LocationErrorType.permissionDenied) ...[
                          TextButton.icon(
                            onPressed: () async {
                              final permission = await LocationService.requestPermission();
                              if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                                AppLocationProvider.switchToCurrentGPS();
                              } else if (permission == LocationPermission.deniedForever) {
                                LocationService.openAppSettings();
                              }
                            },
                            icon: const Icon(Icons.security, size: 14, color: AppColors.primary),
                            label: const Text('Grant Permission', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                          ),
                          TextButton.icon(
                            onPressed: () => LocationService.openAppSettings(),
                            icon: const Icon(Icons.settings, size: 14, color: AppColors.textSecondary),
                            label: const Text('App Settings', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        ] else
                          TextButton.icon(
                            onPressed: () => AppLocationProvider.switchToCurrentGPS(),
                            icon: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                            label: const Text('Retry GPS (15s)', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            else if (locState.location != null)
              AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: const Color(0xFFE8F5E9),
                borderColor: AppColors.primary.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live Location: ${locState.location!.formattedLocation}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                      onPressed: () => AppLocationProvider.switchToCurrentGPS(),
                      tooltip: 'Refresh Location & Soil',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // Community Popular Presets (Only displayed if presets have >= 3 useful votes)
            if (_communityPresets.isNotEmpty) ...[
              AppCard(
                padding: const EdgeInsets.all(14),
                backgroundColor: const Color(0xFFF1F8E9),
                borderColor: AppColors.primary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Popular Presets in ${_selectedDistrict}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _communityPresets.map((preset) {
                        return ActionChip(
                          avatar: const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.primary),
                          label: Text(
                            '${preset.soilType.toUpperCase()} • ${preset.season.toUpperCase()} (${preset.usefulVotes} 👍)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _applyCommunityPreset(preset),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Soil Type Selector
            AppDropdown<String>(
              label: LocalizationService.tr('soil_type'),
              value: _selectedSoil,
              isRequired: true,
              items: [
                AppDropdownItem(value: 'black', label: LocalizationService.tr('soil_black'), icon: Icons.grass),
                AppDropdownItem(value: 'alluvial', label: LocalizationService.tr('soil_alluvial'), icon: Icons.landscape),
                AppDropdownItem(value: 'red', label: LocalizationService.tr('soil_red'), icon: Icons.terrain),
                AppDropdownItem(value: 'clay', label: LocalizationService.tr('soil_clay'), icon: Icons.grain),
                AppDropdownItem(value: 'loamy', label: LocalizationService.tr('soil_loamy'), icon: Icons.filter_vintage),
                AppDropdownItem(value: 'sandy', label: LocalizationService.tr('soil_sandy'), icon: Icons.blur_on),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedSoil = val);
              },
            ),
            const SizedBox(height: 16),

            // Season Selector
            AppDropdown<String>(
              label: LocalizationService.tr('season'),
              value: _selectedSeason,
              isRequired: true,
              items: [
                AppDropdownItem(value: 'kharif', label: LocalizationService.tr('season_kharif'), icon: Icons.umbrella),
                AppDropdownItem(value: 'rabi', label: LocalizationService.tr('season_rabi'), icon: Icons.ac_unit),
                AppDropdownItem(value: 'zaid', label: LocalizationService.tr('season_zaid'), icon: Icons.wb_sunny),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedSeason = val);
              },
            ),
            const SizedBox(height: 16),

            // Water Availability
            AppDropdown<String>(
              label: LocalizationService.tr('water_availability'),
              value: _selectedWater,
              isRequired: true,
              items: [
                AppDropdownItem(value: 'low', label: LocalizationService.tr('water_low'), icon: Icons.opacity),
                AppDropdownItem(value: 'medium', label: LocalizationService.tr('water_medium'), icon: Icons.water_drop),
                AppDropdownItem(value: 'high', label: LocalizationService.tr('water_high'), icon: Icons.waves),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedWater = val);
              },
            ),
            const SizedBox(height: 16),

            // District & Farm Size in 2 columns (Expanded to avoid overflow)
            Builder(
              builder: (context) {
                const stdDistricts = [
                  'Pune, Maharashtra',
                  'Nashik, Maharashtra',
                  'Nagpur, Maharashtra',
                  'Kolhapur, Maharashtra',
                  'Aurangabad, Maharashtra',
                  'Solapur, Maharashtra',
                  'Amravati, Maharashtra',
                ];
                final districtItems = <AppDropdownItem<String>>[
                  if (!stdDistricts.contains(_selectedDistrict))
                    AppDropdownItem(value: _selectedDistrict, label: _selectedDistrict),
                  const AppDropdownItem(value: 'Pune, Maharashtra', label: 'Pune'),
                  const AppDropdownItem(value: 'Nashik, Maharashtra', label: 'Nashik'),
                  const AppDropdownItem(value: 'Nagpur, Maharashtra', label: 'Nagpur'),
                  const AppDropdownItem(value: 'Kolhapur, Maharashtra', label: 'Kolhapur'),
                  const AppDropdownItem(value: 'Aurangabad, Maharashtra', label: 'Aurangabad'),
                  const AppDropdownItem(value: 'Solapur, Maharashtra', label: 'Solapur'),
                  const AppDropdownItem(value: 'Amravati, Maharashtra', label: 'Amravati'),
                ];

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppDropdown<String>(
                        label: LocalizationService.tr('district'),
                        value: _selectedDistrict,
                        items: districtItems,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistrict = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: LocalizationService.tr('farm_size'),
                        hint: LocalizationService.tr('farm_size_hint'),
                        controller: _farmSizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return LocalizationService.tr('error_required');
                          if (double.tryParse(val.trim()) == null) return LocalizationService.tr('error_invalid_number');
                          return null;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Advanced NPK & Soil pH Toggle
            InkWell(
              onTap: () => setState(() => _showAdvancedNpk = !_showAdvancedNpk),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _showAdvancedNpk ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _showAdvancedNpk
                            ? LocalizationService.tr('hide_advanced_soil_data')
                            : LocalizationService.tr('advanced_soil_data'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showAdvancedNpk) ...[
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: AppColors.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: LocalizationService.tr('npk_nitrogen'),
                            hint: 'kg/ha',
                            controller: _nitrogenController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            label: LocalizationService.tr('npk_phosphorus'),
                            hint: 'kg/ha',
                            controller: _phosphorusController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            label: LocalizationService.tr('npk_potassium'),
                            hint: 'kg/ha',
                            controller: _potassiumController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: LocalizationService.tr('soil_ph'),
                      hint: '6.5 - 7.5',
                      controller: _phController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              text: _isLoading
                  ? LocalizationService.tr('btn_loading_recommendations')
                  : LocalizationService.tr('btn_get_recommendations'),
              icon: Icons.lightbulb_outlined,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submitRecommendation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final farmerId = UserService.currentUser?.uid ?? 'guest_farmer';

    return StreamBuilder<List<RecommendationRecord>>(
      stream: CropRecommendationService.streamHistory(farmerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 54, color: AppColors.danger),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to sync past recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_edu_outlined, size: 54, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    LocalizationService.tr('history_empty'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    LocalizationService.tr('history_empty_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final record = records[index];
            final topCrop = record.output.firstOrNull;

            return AppCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecommendationResultScreen(
                      input: record.input,
                      results: record.output,
                      isFromHistory: true,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormatter.format(record.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${record.input.season.toUpperCase()} • ${record.input.soilType.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Top: ${topCrop?.cropName ?? "Crops"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${record.output.length} suitable crops analyzed for ${record.input.farmSizeAcres} acres in ${record.input.district}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}