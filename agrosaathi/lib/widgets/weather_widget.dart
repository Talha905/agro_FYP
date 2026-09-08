import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/weather_model.dart';
import '../services/localization_service.dart';
import '../services/weather_service.dart';

/// Dynamic, animated Agro-Weather Header Card with condition-aware gradients.
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
        return Icons.water_drop_rounded;
      case 'clouds':
      case 'cloudy':
      case 'partly cloudy':
        return Icons.cloud_rounded;
      case 'clear':
      case 'sunny':
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  LinearGradient _getWeatherGradient(bool isRain) {
    if (isRain) {
      return AppColors.rainyGradient;
    }
    return AppColors.sunnyGradient;
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
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.softShadow,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Text('Fetching Live Weather Data...', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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

            final isRain = weather.isRainExpected;
            final gradient = _getWeatherGradient(isRain);

            return Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isRain ? AppColors.accent : AppColors.secondary).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative background graphics
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      _getWeatherIcon(weather.condition),
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Header & District Switcher
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    weather.location,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: _changeDistrict,
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                              ),
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
                        const SizedBox(height: 16),

                        // Temperature & Condition
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                              ),
                              child: Icon(_getWeatherIcon(weather.condition), size: 38, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      weather.temperature.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      '°C',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  weather.getLocalizedCondition(langCode),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Weather Stats Ribbon
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWhiteStat(Icons.water_drop_outlined, '${weather.humidity}%', LocalizationService.tr('humidity')),
                              Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.3)),
                              _buildWhiteStat(Icons.air_rounded, '${weather.windSpeedKmH} km/h', LocalizationService.tr('wind')),
                              Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.3)),
                              _buildWhiteStat(Icons.umbrella_outlined, '${weather.rainProbability}%', LocalizationService.tr('rain_chance')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Agricultural Advisory Callout
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isRain ? Icons.warning_amber_rounded : Icons.eco_rounded,
                                color: isRain ? AppColors.warning : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService.tr('weather_advisory'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isRain ? AppColors.warning : AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      weather.getLocalizedAdvisory(langCode),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWhiteStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Colors.white70),
        ),
      ],
    );
  }
}
