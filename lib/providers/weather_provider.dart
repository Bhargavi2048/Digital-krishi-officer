import 'package:flutter/material.dart';
import '../core/services/weather_service.dart';
import '../core/services/location_detector_service.dart';
import '../core/storage/local_storage_service.dart';
import '../models/weather_data.dart';
import '../models/farmer_profile.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocalStorageService _storage = LocalStorageService();

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentLocationName = 'Thanjavur, Tamil Nadu';
  String _langCode = 'en';

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentLocationName => _currentLocationName;
  String get currentLanguageCode => _langCode;

  WeatherProvider() {
    _langCode = _storage.getLanguage();
    final storedUser = _storage.getUser();
    loadWeather(profile: storedUser);
  }

  Future<void> loadWeather({
    FarmerProfile? profile,
    double? latitude,
    double? longitude,
    bool resetToProfile = false,
    String? langCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (langCode != null && langCode.isNotEmpty) {
      _langCode = langCode;
    }
    notifyListeners();

    final activeProfile = profile ?? _storage.getUser();
    if ((_currentLocationName.isEmpty || resetToProfile) && activeProfile != null) {
      final city = activeProfile.city.trim();
      final district = activeProfile.district.trim();
      final state = activeProfile.state.trim();

      if (city.isNotEmpty && district.isNotEmpty && city.toLowerCase() != district.toLowerCase()) {
        _currentLocationName = '$city, $district';
      } else if (district.isNotEmpty) {
        _currentLocationName = '$district, $state';
      } else if (city.isNotEmpty) {
        _currentLocationName = '$city, $state';
      }
    }

    try {
      final data = await _weatherService.fetchWeather(
        locationName: _currentLocationName,
        cropName: activeProfile?.mainCrop ?? 'Paddy',
        latitude: latitude,
        longitude: longitude,
        langCode: _langCode,
      );
      _weatherData = data;

      // Automatically generate weather-driven alerts if severe conditions exist
      final alerts = _weatherService.generateWeatherAlerts(data, profile?.mainCrop ?? 'Paddy');
      for (final alert in alerts) {
        await _storage.saveAlert(alert);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not load weather: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLanguage(String newLangCode) {
    _langCode = newLangCode;
    if (_weatherData != null) {
      final activeProfile = _storage.getUser();
      final updatedAdvisory = _weatherService.generateAdvisoryForLanguage(
        temp: _weatherData!.temperature,
        humidity: _weatherData!.humidity,
        rainProb: _weatherData!.rainProbability,
        windSpeed: _weatherData!.windSpeed,
        cropName: activeProfile?.mainCrop ?? 'Paddy',
        langCode: newLangCode,
      );
      _weatherData = _weatherData!.copyWith(agriculturalAdvisory: updatedAdvisory);
      notifyListeners();
    }
  }

  Future<void> changeLocation(String newLocation, {String cropName = 'Paddy'}) async {
    _currentLocationName = newLocation;
    await loadWeather();
  }

  Future<void> updateCurrentCoordinates(double lat, double lon, String detectedPlace) async {
    _currentLocationName = detectedPlace;
    await loadWeather(latitude: lat, longitude: lon);
  }

  /// Automatically detects user's live physical location and refreshes weather
  Future<void> detectAndLoadLocationWeather({FarmerProfile? profile}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detected = await LocationDetectorService().detectCurrentLocation();
      if (detected != null) {
        final locationStr = (detected.district.isNotEmpty && detected.state.isNotEmpty)
            ? '${detected.district}, ${detected.state}'
            : (detected.city.isNotEmpty ? detected.city : 'Current Location');
        _currentLocationName = locationStr;

        if (detected.latitude != null && detected.longitude != null) {
          await loadWeather(
            profile: profile,
            latitude: detected.latitude,
            longitude: detected.longitude,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Auto-location detection exception: $e');
    }

    // Fallback to profile or default location
    await loadWeather(profile: profile);
  }
}
