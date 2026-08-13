import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/weather_model.dart';
import '../services/localization_service.dart';
import '../services/weather_service.dart';
import 'app_card.dart';

/// Dynamic Agro-Weather Card for Home Dashboard.
/// Owned by Person A. Fully responsive and multi-language enabled.
class WeatherWidget extends StatefulWidget {
  final VoidCallback? onAlertsTap;

  const WeatherWidget({
    super.key,
    this.onAlertsTap,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String selectedDistrict = 'Pune, Maharashtra';
  late Future<WeatherInfo> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService.fetchWeather(location: selectedDistrict);
  }

  void _changeDistrict(String newDistrict) {
    setState(() {
      selectedDistrict = newDistrict;
      _weatherFuture = WeatherService.fetchWeather(location: selectedDistrict);
    });
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'rainy':
      case 'drizzle':
      case 'thunderstorm':
        return Icons.water_drop;
      case 'clouds':
      case 'cloudy':
      case 'partly cloudy':
        return Icons.cloud_queue;
      case 'clear':
      case 'sunny':
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, langCode, _) {
        return FutureBuilder<WeatherInfo>(
          future: _weatherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppCard(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationService.tr('loading'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            final weather = snapshot.data ??
                WeatherInfo(
                  location: selectedDistrict,
                  temperature: 29.0,
                  condition: 'Partly Cloudy',
                  conditionKey: 'weather_partly_cloudy',
                  conditionDescription: 'Partly Cloudy',
                  humidity: 55,
                  windSpeedKmH: 12.0,
                  rainProbability: 20,
                  advisoryKey: 'advisory_favorable',
                  agriculturalAdvisory: 'Good weather for farm operations.',
                  isRainExpected: false,
                  lastUpdated: DateTime.now(),
                );

            return AppCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location header & district switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                weather.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: _changeDistrict,
                        icon: const Icon(Icons.tune, size: 18, color: AppColors.textSecondary),
                        itemBuilder: (context) {
                          return WeatherService.supportedDistricts.map((district) {
                            return PopupMenuItem(
                              value: district,
                              child: Text(district),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Temperature & main icon (Wrapped with Expanded to prevent overflow)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: weather.isRainExpected ? AppColors.accentLight : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getWeatherIcon(weather.condition),
                          size: 36,
                          color: weather.isRainExpected ? AppColors.accent : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  weather.temperature.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  '°C',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              weather.getLocalizedCondition(langCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stats Row: Humidity, Wind, Rain (Expanded to prevent overflow)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            Icons.water_drop_outlined,
                            '${weather.humidity}%',
                            LocalizationService.tr('humidity'),
                          ),
                        ),
                        Container(height: 24, width: 1, color: AppColors.cardBorder),
                        Expanded(
                          child: _buildStatItem(
                            Icons.air,
                            '${weather.windSpeedKmH} km/h',
                            LocalizationService.tr('wind'),
                          ),
                        ),
                        Container(height: 24, width: 1, color: AppColors.cardBorder),
                        Expanded(
                          child: _buildStatItem(
                            Icons.umbrella_outlined,
                            '${weather.rainProbability}%',
                            LocalizationService.tr('rain_chance'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Agricultural Advisory (Fully Localized)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: weather.isRainExpected ? AppColors.warningLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: weather.isRainExpected
                            ? AppColors.warning.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          weather.isRainExpected ? Icons.warning_amber_rounded : Icons.eco,
                          size: 18,
                          color: weather.isRainExpected ? AppColors.warning : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.tr('weather_advisory'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: weather.isRainExpected ? AppColors.warning : AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                weather.getLocalizedAdvisory(langCode),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: weather.isRainExpected ? AppColors.warning : AppColors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
