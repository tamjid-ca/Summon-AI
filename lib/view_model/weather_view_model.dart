import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:summon_ai/model/weather_model.dart';
import 'package:summon_ai/service/user_data_service.dart';
import 'package:summon_ai/service/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _service = WeatherService();
  final UserDataService _userDataService = UserDataService();

  bool isLoadingCurrent = false;
  bool isLoadingSearch = false;
  WeatherModel? currentLocationWeather;
  WeatherModel? searchedWeather;
  String? errorMessage;
  String? searchErrorMessage;

  /// History of searched locations (newest first)
  final List<WeatherModel> savedLocations = [];

  Future<void> loadUserHistory() async {
    try {
      final searches = await _userDataService.loadWeatherSearches();
      savedLocations
        ..clear()
        ..addAll(searches);
      searchedWeather = savedLocations.isNotEmpty ? savedLocations.first : null;
      notifyListeners();
    } catch (_) {
      searchErrorMessage = 'Could not load saved weather searches.';
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // Current Location
  // ──────────────────────────────────────────────

  Future<void> fetchCurrentLocation() async {
    isLoadingCurrent = true;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await _determinePosition();
      currentLocationWeather = await _service.fetchWeatherByCoords(
        position.latitude,
        position.longitude,
      );
    } on Exception catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } catch (e) {
      errorMessage = 'Could not fetch current location weather.';
    } finally {
      isLoadingCurrent = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // Custom City Search
  // ──────────────────────────────────────────────

  Future<void> fetchWeatherByCity(String city) async {
    if (city.trim().isEmpty) return;
    isLoadingSearch = true;
    searchErrorMessage = null;
    notifyListeners();

    try {
      final weather = await _service.fetchWeatherByCity(city.trim());
      searchedWeather = weather;

      // Add to history, avoid duplicates by location name
      savedLocations.removeWhere(
        (w) => w.location.name.toLowerCase() == weather.location.name.toLowerCase(),
      );
      savedLocations.insert(0, weather);
      unawaited(_userDataService.saveWeatherSearch(weather));

      // Keep at most 10 saved locations
      if (savedLocations.length > 10) savedLocations.removeLast();
    } on Exception catch (e) {
      searchErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } catch (e) {
      searchErrorMessage = 'Could not fetch weather for "$city".';
    } finally {
      isLoadingSearch = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchedWeather = null;
    searchErrorMessage = null;
    notifyListeners();
  }

  void clearSavedLocations() {
    savedLocations.clear();
    searchedWeather = null;
    searchErrorMessage = null;
    unawaited(_userDataService.clearWeatherSearches());
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Geolocator helpers
  // ──────────────────────────────────────────────

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable them in Settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Please enable it in App Settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
