import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import 'location_service.dart';
import 'soil_grids_service.dart';
import 'weather_service.dart';

enum LocationStatus {
  idle,
  detecting,
  success,
  manual,
  error,
}

class LocationState {
  final LocationStatus status;
  final LocationData? location;
  final WeatherInfo? weather;
  final SoilPropertyData? soil;
  final LocationErrorType? errorType;
  final String? errorMessage;
  final bool isManual;
  final String? lastKnownDistrict;

  LocationState({
    required this.status,
    this.location,
    this.weather,
    this.soil,
    this.errorType,
    this.errorMessage,
    this.isManual = false,
    this.lastKnownDistrict,
  });

  String get displayDistrict {
    if (isManual && location != null) return '${location!.district} (Manual)';
    if (location != null) return location!.formattedLocation;
    if (lastKnownDistrict != null && lastKnownDistrict!.isNotEmpty) return '$lastKnownDistrict (Last Known)';
    return 'Location Unavailable';
  }
}

class AppLocationProvider {
  static final ValueNotifier<LocationState> stateNotifier = ValueNotifier<LocationState>(
    LocationState(status: LocationStatus.idle),
  );

  static LocationState get currentState => stateNotifier.value;

  /// Initializes location fetching. A fresh GPS result ALWAYS wins.
  /// Last known location is saved to SharedPreferences as a fallback only.
  static Future<void> initLocation({bool forceFresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDistrict = prefs.getString('last_known_district');
    final savedLat = prefs.getDouble('last_known_lat');
    final savedLon = prefs.getDouble('last_known_lon');

    // 1. Indicate loading state
    stateNotifier.value = LocationState(
      status: LocationStatus.detecting,
      lastKnownDistrict: savedDistrict,
    );

    // 2. Fetch fresh GPS position
    final result = await LocationService.getCurrentLocation();

    if (result.isSuccess && result.location != null) {
      final freshLoc = result.location!;

      // Save fresh location to SharedPreferences as fallback for future offline runs
      await prefs.setString('last_known_district', freshLoc.formattedLocation);
      await prefs.setDouble('last_known_lat', freshLoc.latitude);
      await prefs.setDouble('last_known_lon', freshLoc.longitude);

      // Fetch Weather & Soil for fresh GPS coordinates
      final weather = await WeatherService.fetchWeatherByCoordinates(
        latitude: freshLoc.latitude,
        longitude: freshLoc.longitude,
        defaultLocation: freshLoc.formattedLocation,
      );
      final soil = await SoilGridsService.fetchSoilProperties(freshLoc.latitude, freshLoc.longitude);

      stateNotifier.value = LocationState(
        status: LocationStatus.success,
        location: freshLoc,
        weather: weather,
        soil: soil,
        isManual: false,
      );
    } else {
      // GPS failed / disabled / permission denied
      if (savedDistrict != null && savedLat != null && savedLon != null) {
        // Fall back to last known location with error warning
        final fallbackLoc = LocationData(
          latitude: savedLat,
          longitude: savedLon,
          city: savedDistrict.split(',').first.trim(),
          state: savedDistrict.contains(',') ? savedDistrict.split(',').last.trim() : 'State',
          district: savedDistrict,
        );
        final weather = await WeatherService.fetchWeatherByCoordinates(
          latitude: savedLat,
          longitude: savedLon,
          defaultLocation: savedDistrict,
        );

        stateNotifier.value = LocationState(
          status: LocationStatus.error,
          location: fallbackLoc,
          weather: weather,
          errorType: result.errorType,
          errorMessage: result.errorMessage,
          lastKnownDistrict: savedDistrict,
        );
      } else {
        stateNotifier.value = LocationState(
          status: LocationStatus.error,
          errorType: result.errorType,
          errorMessage: result.errorMessage ?? 'GPS Location unavailable.',
        );
      }
    }
  }

  /// Sets a manual location selection and fetches weather/soil for it.
  static Future<void> setManualLocation(String district, {double? lat, double? lon}) async {
    stateNotifier.value = LocationState(
      status: LocationStatus.detecting,
      lastKnownDistrict: currentState.lastKnownDistrict,
    );

    final useLat = lat ?? 18.5204;
    final useLon = lon ?? 73.8567;

    final loc = LocationData(
      latitude: useLat,
      longitude: useLon,
      city: district.split(',').first.trim(),
      state: district.contains(',') ? district.split(',').last.trim() : 'Maharashtra',
      district: district,
    );

    final weather = await WeatherService.fetchWeather(location: district);
    final soil = await SoilGridsService.fetchSoilProperties(useLat, useLon);

    stateNotifier.value = LocationState(
      status: LocationStatus.manual,
      location: loc,
      weather: weather,
      soil: soil,
      isManual: true,
    );
  }

  /// Switches back to fresh current GPS location
  static Future<void> switchToCurrentGPS() async {
    await initLocation(forceFresh: true);
  }
}
