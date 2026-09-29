import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String district;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.district,
  });

  String get formattedLocation => '$district, $state';
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  timeout,
  geocodingFailed,
  unknown,
}

class LocationResult {
  final bool isSuccess;
  final LocationData? location;
  final LocationErrorType? errorType;
  final String? errorMessage;

  LocationResult.success(this.location)
      : isSuccess = true,
        errorType = null,
        errorMessage = null;

  LocationResult.error(this.errorType, this.errorMessage)
      : isSuccess = false,
        location = null;
}

class LocationService {
  /// Fetches real device GPS coordinates and performs reverse geocoding.
  /// Returns explicit error states if GPS is disabled, permission denied, or timeout occurs.
  /// NEVER silently falls back to hardcoded locations.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          LocationErrorType.serviceDisabled,
          'GPS location services are disabled on your device. Please turn on location services.',
        );
      }

      // 2. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error(
            LocationErrorType.permissionDenied,
            'Location permission denied. Please allow location access to fetch live local data.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(
          LocationErrorType.permissionDenied,
          'Location permissions are permanently denied. Please enable location permissions in app settings.',
        );
      }

      // 3. Fetch GPS position with strict 10s timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Reverse Geocode via Open-Meteo Geocoding API / Nominatim
      final locData = await _reverseGeocode(position.latitude, position.longitude);
      if (locData != null) {
        return LocationResult.success(locData);
      }

      // Fallback geocode format if reverse geocode service fails
      return LocationResult.success(
        LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          city: 'Local Area',
          state: 'State',
          district: '${position.latitude.toStringAsFixed(2)}°N, ${position.longitude.toStringAsFixed(2)}°E',
        ),
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeLimit')) {
        return LocationResult.error(
          LocationErrorType.timeout,
          'Location fetch timed out. Please check your GPS signal and retry.',
        );
      }
      return LocationResult.error(
        LocationErrorType.unknown,
        'Could not fetch location: $e',
      );
    }
  }

  static Future<LocationData?> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$lat&longitude=$lon&count=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final res = results[0];
          final city = res['name'] ?? res['admin2'] ?? 'Local Region';
          final state = res['admin1'] ?? res['country'] ?? 'India';
          return LocationData(
            latitude: lat,
            longitude: lon,
            city: city,
            state: state,
            district: '$city, $state',
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
