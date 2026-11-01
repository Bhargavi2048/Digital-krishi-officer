import 'dart:convert';

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final int rainProbability;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.rainProbability,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'condition': condition,
      'rainProbability': rainProbability,
    };
  }

  factory DailyForecast.fromMap(Map<String, dynamic> map) {
    return DailyForecast(
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      maxTemp: (map['maxTemp'] is num) ? (map['maxTemp'] as num).toDouble() : 30.0,
      minTemp: (map['minTemp'] is num) ? (map['minTemp'] as num).toDouble() : 22.0,
      condition: map['condition'] ?? 'Partly Cloudy',
      rainProbability: (map['rainProbability'] is num) ? (map['rainProbability'] as num).toInt() : 20,
    );
  }
}

class WeatherData {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final int rainProbability;
  final String locationName;
  final DateTime lastUpdated;
  final List<DailyForecast> forecast;
  final String agriculturalAdvisory;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.rainProbability,
    required this.locationName,
    DateTime? lastUpdated,
    List<DailyForecast>? forecast,
    this.agriculturalAdvisory = '',
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        forecast = forecast ?? [];

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'condition': condition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'rainProbability': rainProbability,
      'locationName': locationName,
      'lastUpdated': lastUpdated.toIso8601String(),
      'forecast': forecast.map((f) => f.toMap()).toList(),
      'agriculturalAdvisory': agriculturalAdvisory,
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temperature: (map['temperature'] is num) ? (map['temperature'] as num).toDouble() : 28.0,
      condition: map['condition'] ?? 'Clear',
      humidity: (map['humidity'] is num) ? (map['humidity'] as num).toInt() : 65,
      windSpeed: (map['windSpeed'] is num) ? (map['windSpeed'] as num).toDouble() : 12.0,
      rainProbability: (map['rainProbability'] is num) ? (map['rainProbability'] as num).toInt() : 15,
      locationName: map['locationName'] ?? 'Farm Location',
      lastUpdated: map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated']) ?? DateTime.now() : DateTime.now(),
      forecast: map['forecast'] != null
          ? (map['forecast'] as List).map((f) => DailyForecast.fromMap(f)).toList()
          : [],
      agriculturalAdvisory: map['agriculturalAdvisory'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherData.fromJson(String source) => WeatherData.fromMap(json.decode(source));

  WeatherData copyWith({
    double? temperature,
    String? condition,
    int? humidity,
    double? windSpeed,
    int? rainProbability,
    String? locationName,
    DateTime? lastUpdated,
    List<DailyForecast>? forecast,
    String? agriculturalAdvisory,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      rainProbability: rainProbability ?? this.rainProbability,
      locationName: locationName ?? this.locationName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      forecast: forecast ?? this.forecast,
      agriculturalAdvisory: agriculturalAdvisory ?? this.agriculturalAdvisory,
    );
  }
}
