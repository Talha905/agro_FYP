import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

/// Weather service integrating OpenWeatherMap with robust agro-climatic fallback
/// for key agricultural districts in Maharashtra and India.
class WeatherService {
  static String apiKey = "8d3de6c4c925d481b7e4282855a8dc95";
  static const String baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  static final Map<String, WeatherInfo> _districtFallbackData = {
    'Pune, Maharashtra': WeatherInfo(
      location: 'Pune, Maharashtra',
      temperature: 29.5,
      condition: 'Partly Cloudy',
      conditionKey: 'weather_partly_cloudy',
      conditionDescription: 'Partly Cloudy',
      humidity: 58,
      windSpeedKmH: 14.2,
      rainProbability: 25,
      advisoryKey: 'advisory_favorable',
      agriculturalAdvisory: 'Favorable condition: Ideal day for fertilizer application, foliar spraying, and intercultural weeding.',
      isRainExpected: false,
      lastUpdated: DateTime.now(),
    ),
    'Nashik, Maharashtra': WeatherInfo(
      location: 'Nashik, Maharashtra',
      temperature: 28.0,
      condition: 'Clear',
      conditionKey: 'weather_clear',
      conditionDescription: 'Clear Sky',
      humidity: 52,
      windSpeedKmH: 11.5,
      rainProbability: 10,
      advisoryKey: 'advisory_nashik',
      agriculturalAdvisory: 'Optimal weather for vineyard pruning, onion nursery transplanting, and morning drip irrigation.',
      isRainExpected: false,
      lastUpdated: DateTime.now(),
    ),
    'Nagpur, Maharashtra': WeatherInfo(
      location: 'Nagpur, Maharashtra',
      temperature: 34.0,
      condition: 'Sunny',
      conditionKey: 'weather_sunny',
      conditionDescription: 'Sunny and warm',
      humidity: 45,
      windSpeedKmH: 9.8,
      rainProbability: 5,
      advisoryKey: 'advisory_nagpur',
      agriculturalAdvisory: 'High temperature: Provide adequate moisture to orange and cotton plots; irrigate during early morning or late evening.',
      isRainExpected: false,
      lastUpdated: DateTime.now(),
    ),
    'Kolhapur, Maharashtra': WeatherInfo(
      location: 'Kolhapur, Maharashtra',
      temperature: 27.5,
      condition: 'Rainy',
      conditionKey: 'weather_rain',
      conditionDescription: 'Rain / Showers',
      humidity: 78,
      windSpeedKmH: 16.0,
      rainProbability: 75,
      advisoryKey: 'advisory_kolhapur',
      agriculturalAdvisory: 'Rain expected: Delay pesticide spraying on sugarcane and hold off scheduled irrigation to prevent waterlogging.',
      isRainExpected: true,
      lastUpdated: DateTime.now(),
    ),
    'Aurangabad, Maharashtra': WeatherInfo(
      location: 'Aurangabad, Maharashtra',
      temperature: 31.0,
      condition: 'Clear',
      conditionKey: 'weather_clear',
      conditionDescription: 'Clear Sky',
      humidity: 50,
      windSpeedKmH: 12.0,
      rainProbability: 15,
      advisoryKey: 'advisory_aurangabad',
      agriculturalAdvisory: 'Good weather for harvesting pulses and soil preparation for upcoming sowing.',
      isRainExpected: false,
      lastUpdated: DateTime.now(),
    ),
  };

  static List<String> get supportedDistricts => _districtFallbackData.keys.toList();

  /// Fetches live weather using Open-Meteo API by GPS coordinates
  static Future<WeatherInfo> fetchWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String defaultLocation = 'Local Region',
  }) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$latitude&longitude=$longitude&'
        'current=temperature_2m,relative_humidity_2m,rain,surface_pressure,wind_speed_10m&'
        'daily=rain_sum,precipitation_probability_max&timezone=auto',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'] ?? {};
        final daily = data['daily'] ?? {};

        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 55;
        final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 12.0;
        final rainMm = (current['rain'] as num?)?.toDouble() ?? 0.0;

        final rainProbList = daily['precipitation_probability_max'] as List?;
        final rainProb = (rainProbList != null && rainProbList.isNotEmpty)
            ? (rainProbList[0] as num).toInt()
            : (rainMm > 0 ? 80 : 20);

        final isRain = rainMm > 0.5 || rainProb > 50;
        final condition = isRain ? 'Rainy' : (temp > 32 ? 'Sunny' : 'Partly Cloudy');

        return WeatherInfo(
          location: defaultLocation,
          temperature: temp,
          condition: condition,
          conditionKey: isRain ? 'weather_rain' : 'weather_partly_cloudy',
          conditionDescription: condition,
          humidity: humidity,
          windSpeedKmH: wind,
          rainProbability: rainProb,
          advisoryKey: isRain ? 'advisory_kolhapur' : 'advisory_favorable',
          agriculturalAdvisory: isRain
              ? 'Rain expected in field: Hold scheduled irrigation and delay foliar spraying.'
              : 'Optimal weather: Suitable for fertilizer application and field operations.',
          isRainExpected: isRain,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (_) {}

    return _districtFallbackData[defaultLocation] ??
        _districtFallbackData['Pune, Maharashtra']!;
  }

  static Future<WeatherInfo> fetchWeather({String location = 'Pune, Maharashtra'}) async {
    try {
      final queryCity = location.split(',').first.trim();
      final url = Uri.parse('$baseUrl?q=$queryCity,IN&units=metric&appid=$apiKey');

      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherInfo.fromJson(data, defaultLocation: location);
      }
    } catch (_) {
      // Graceful fallback to offline/cached agricultural dataset
    }

    return _districtFallbackData[location] ??
        _districtFallbackData['Pune, Maharashtra']!;
  }
}
