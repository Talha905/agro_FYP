import '../constants/app_translations.dart';

/// Weather data and agricultural advisory model.
class WeatherInfo {
  final String location;
  final double temperature; // Celsius
  final String condition; // 'Sunny', 'Rainy', 'Cloudy', 'Partly Cloudy', etc.
  final String conditionKey; // translation key
  final String conditionDescription;
  final int humidity; // %
  final double windSpeedKmH;
  final int rainProbability; // 0 - 100%
  final String advisoryKey; // translation key
  final String agriculturalAdvisory;
  final bool isRainExpected;
  final DateTime lastUpdated;

  WeatherInfo({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.conditionKey,
    required this.conditionDescription,
    required this.humidity,
    required this.windSpeedKmH,
    required this.rainProbability,
    required this.advisoryKey,
    required this.agriculturalAdvisory,
    required this.isRainExpected,
    required this.lastUpdated,
  });

  String getLocalizedCondition(String langCode) {
    return AppTranslations.get(conditionKey, lang: langCode);
  }

  String getLocalizedAdvisory(String langCode) {
    final translated = AppTranslations.get(advisoryKey, lang: langCode);
    return translated.isNotEmpty ? translated : agriculturalAdvisory;
  }

  factory WeatherInfo.fromJson(Map<String, dynamic> json, {String defaultLocation = 'Pune, Maharashtra'}) {
    final main = json['main'] ?? {};
    final weatherList = (json['weather'] as List?)?.firstOrNull ?? {};
    final wind = json['wind'] ?? {};
    final clouds = json['clouds'] ?? {};

    final temp = (main['temp'] as num?)?.toDouble() ?? 28.0;
    final cond = weatherList['main'] ?? 'Clear';
    final hum = (main['humidity'] as num?)?.toInt() ?? 55;
    final windSpeed = ((wind['speed'] as num?)?.toDouble() ?? 3.5) * 3.6; // convert m/s to km/h
    final rainProb = cond.toString().toLowerCase().contains('rain') ? 85 : ((clouds['all'] as num?)?.toInt() ?? 20);
    final isRain = rainProb > 50;

    String condKey = 'weather_clear';
    final condLower = cond.toString().toLowerCase();
    if (condLower.contains('rain') || condLower.contains('drizzle')) {
      condKey = 'weather_rain';
    } else if (condLower.contains('cloud')) {
      condKey = 'weather_partly_cloudy';
    } else if (condLower.contains('thunder')) {
      condKey = 'weather_thunderstorm';
    }

    String advKey = 'advisory_favorable';
    String advisoryText = 'Favorable condition: Ideal day for fertilizer application, foliar spraying, and field intercultural operations.';

    if (isRain) {
      advKey = 'advisory_rain';
      advisoryText = 'Rain anticipated: Postpone foliar spraying and hold off scheduled irrigation to avoid waterlogging.';
    } else if (temp > 35) {
      advKey = 'advisory_heat';
      advisoryText = 'High temperature alert: Ensure sufficient soil moisture for vegetative crops during midday.';
    } else if (hum > 80) {
      advKey = 'advisory_humidity';
      advisoryText = 'High humidity: Monitor closely for fungal infestations or leaf blight in sensitive crops.';
    }

    return WeatherInfo(
      location: json['name'] ?? defaultLocation,
      temperature: temp,
      condition: cond,
      conditionKey: condKey,
      conditionDescription: AppTranslations.get(condKey),
      humidity: hum,
      windSpeedKmH: double.parse(windSpeed.toStringAsFixed(1)),
      rainProbability: rainProb,
      advisoryKey: advKey,
      agriculturalAdvisory: advisoryText,
      isRainExpected: isRain,
      lastUpdated: DateTime.now(),
    );
  }
}
