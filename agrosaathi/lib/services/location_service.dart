import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String district;
  final bool isFallbackCoordinates;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.district,
    this.isFallbackCoordinates = false,
  });

  String get formattedLocation {
    if (isFallbackCoordinates) {
      return 'Coordinates: ${latitude.toStringAsFixed(2)}°N, ${longitude.toStringAsFixed(2)}°E';
    }
    return district;
  }

  /// Extracts the clean broad district name (e.g., "Mumbai City" or "Pune" or "Nashik")
  /// excluding neighbourhoods and division names ("Konkan Division").
  String get broadDistrictName => LocationService.extractBroadDistrict(district);
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
  static final Map<String, LocationData> _geocodeCache = {};
  static DateTime _lastNominatimRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Helper to check if a string represents an administrative division (e.g. "Konkan Division")
  static bool _isDivisionName(String? name) {
    if (name == null || name.trim().isEmpty) return true;
    final lower = name.toLowerCase().trim();
    return lower.endsWith('division') || lower.contains(' division');
  }

  /// Extracts clean broad district name from a location string.
  /// Example: "Byculla, Konkan Division, Maharashtra" -> "Mumbai City" (or district part)
  /// "Pune, Maharashtra" -> "Pune, Maharashtra"
  static String extractBroadDistrict(String rawLocation) {
    final parts = rawLocation
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !_isDivisionName(s))
        .toList();

    if (parts.isEmpty) return 'Pune, Maharashtra';
    if (parts.length == 1) return '${parts.first}, Maharashtra';
    // If city and state or city, district, state: return district + state or main area
    final mainDistrict = parts.length >= 2 ? parts[parts.length - 2] : parts.first;
    final state = parts.last;
    return '$mainDistrict, $state';
  }

  /// Opens device GPS location settings screen
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Opens app settings screen for permissions
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Requests location permission again
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Fetches real device GPS coordinates and performs reverse geocoding.
  /// Returns explicit error states if GPS is disabled, permission denied, or timeout occurs.
  static Future<LocationResult> getCurrentLocation({int timeoutSeconds = 12}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          LocationErrorType.serviceDisabled,
          'GPS location services are disabled on your device. Please turn on location services.',
        );
      }

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

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: timeoutSeconds),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return LocationResult.error(
          LocationErrorType.timeout,
          'Location fetch timed out. Please check your GPS signal and tap Retry.',
        );
      }

      final locData = await reverseGeocode(position.latitude, position.longitude);
      return LocationResult.success(locData);
    } catch (e) {
      return LocationResult.error(
        LocationErrorType.unknown,
        'Could not fetch location: $e',
      );
    }
  }

  /// Reverse geocodes coordinates to "City/Town, District, State" format.
  /// Uses Flutter `geocoding` package first, falls back to Nominatim with 1s rate limit & caching.
  static Future<LocationData> reverseGeocode(double lat, double lon) async {
    final cacheKey = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    if (_geocodeCache.containsKey(cacheKey)) {
      return _geocodeCache[cacheKey]!;
    }

    // 1. Primary: Flutter geocoding package (placemarkFromCoordinates)
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon).timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = [place.subLocality, place.locality]
            .where((s) => s != null && s.trim().isNotEmpty)
            .firstOrNull ?? 'Local Area';

        // Skip division names like "Konkan Division"
        String? validDistrict;
        if (!_isDivisionName(place.subAdministrativeArea)) {
          validDistrict = place.subAdministrativeArea;
        } else if (!_isDivisionName(place.locality)) {
          validDistrict = place.locality;
        } else if (!_isDivisionName(place.subLocality)) {
          validDistrict = place.subLocality;
        } else {
          validDistrict = city;
        }

        final state = place.administrativeArea ?? place.country ?? 'State';

        final parts = [city, validDistrict, state]
            .where((s) => s != null && s.trim().isNotEmpty && !_isDivisionName(s))
            .toSet()
            .join(', ');

        final data = LocationData(
          latitude: lat,
          longitude: lon,
          city: city,
          state: state,
          district: parts.isNotEmpty ? parts : '$city, $state',
        );
        _geocodeCache[cacheKey] = data;
        return data;
      }
    } catch (e) {
      debugPrint('[ReverseGeocode] Native geocoding failed ($e); attempting Nominatim fallback...');
    }

    // 2. Secondary: Nominatim API fallback with 1 request/sec rate limiting
    try {
      final now = DateTime.now();
      final elapsedSinceLastReq = now.difference(_lastNominatimRequestTime);
      if (elapsedSinceLastReq < const Duration(seconds: 1)) {
        await Future.delayed(const Duration(seconds: 1) - elapsedSinceLastReq);
      }
      _lastNominatimRequestTime = DateTime.now();

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AgroSaathiApp/1.0 (contact@agrosaathi.com)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final addr = json['address'] as Map<String, dynamic>? ?? {};
        final city = addr['suburb'] ?? addr['town'] ?? addr['city'] ?? addr['village'] ?? 'Local Region';

        String districtRaw = (addr['county'] ?? addr['state_district'] ?? addr['district'] ?? city).toString();
        if (_isDivisionName(districtRaw)) {
          districtRaw = city.toString();
        }
        final state = (addr['state'] ?? addr['country'] ?? 'State').toString();

        final formattedDistrict = [city.toString(), districtRaw, state]
            .where((s) => s.trim().isNotEmpty && !_isDivisionName(s))
            .toSet()
            .join(', ');

        final data = LocationData(
          latitude: lat,
          longitude: lon,
          city: city.toString(),
          state: state,
          district: formattedDistrict,
        );
        _geocodeCache[cacheKey] = data;
        return data;
      }
    } catch (e) {
      debugPrint('[ReverseGeocode] Nominatim fallback failed: $e');
    }

    // 3. Labelled last resort if all reverse geocoders fail
    final fallbackData = LocationData(
      latitude: lat,
      longitude: lon,
      city: 'Local Region',
      state: 'State',
      district: 'Coordinates: ${lat.toStringAsFixed(2)}°N, ${lon.toStringAsFixed(2)}°E',
      isFallbackCoordinates: true,
    );
    _geocodeCache[cacheKey] = fallbackData;
    return fallbackData;
  }
}
