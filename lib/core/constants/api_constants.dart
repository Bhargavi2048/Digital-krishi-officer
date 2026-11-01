import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Google Gemini API Base
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String defaultGeminiModel = 'gemini-3.8-flash';

  // Java Spring Boot Backend Base URL
  static String get springBootBaseUrl {
    try {
      final envUrl = dotenv.env['BACKEND_API_URL'];
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        final clean = envUrl.trim();
        return clean.endsWith('/api') ? clean : (clean.endsWith('/') ? '${clean}api' : '$clean/api');
      }
    } catch (_) {}
    return 'https://krishi-backend-i0ub.onrender.com/api';
  }

  static const String springBootAndroidUrl = 'http://10.0.2.2:8080/api';

  // Open-Meteo Weather Base (Free, no API key required, reliable for Indian coordinates)
  static const String openMeteoForecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoGeocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  // OpenWeatherMap API Base and Key
  static const String openWeatherMapBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String defaultOpenWeatherApiKey = '671d789ae40566e427e7762d4d80fa58';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
