import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/location_data.dart';
import '../../models/weather_data.dart';
import '../../models/farmer_alert.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  String get apiKey {
    try {
      final key = dotenv.env['WEATHER_API_KEY'];
      if (key != null && key.trim().isNotEmpty && key != 'YOUR_WEATHER_API_KEY') {
        return key.trim();
      }
    } catch (_) {}
    return ApiConstants.defaultOpenWeatherApiKey;
  }

  // Geocodes location name to latitude & longitude using local dictionary + Open-Meteo fallback
  Future<Map<String, double>> _getCoordinates(String cityName) async {
    // 1. Instant check in high-precision local database
    final localLookup = LocationData.lookupCoordinates(cityName);
    if (localLookup != null) {
      return localLookup;
    }

    // 2. Split compound strings (e.g. "Adyar, Chennai, Tamil Nadu") and check tokens
    for (final part in cityName.split(',')) {
      final tokenLookup = LocationData.lookupCoordinates(part.trim());
      if (tokenLookup != null) {
        return tokenLookup;
      }
    }

    // 3. Fallback to Open-Meteo Geocoding API
    try {
      final query = Uri.encodeComponent(cityName.trim());
      final url = Uri.parse('${ApiConstants.openMeteoGeocodingUrl}?name=$query&count=1&language=en&format=json');
      final res = await http.get(url).timeout(ApiConstants.connectTimeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          return {
            'lat': (first['latitude'] as num).toDouble(),
            'lon': (first['longitude'] as num).toDouble(),
          };
        }
      }
    } catch (_) {}

    // Default fallback to Thanjavur (Tamil Nadu)
    return {'lat': 10.7867, 'lon': 79.1378};
  }

  // Fetches live weather using Open-Meteo REST API
  Future<WeatherData> fetchWeather({
    String locationName = 'Thanjavur, Tamil Nadu',
    String cropName = 'Paddy (Rice)',
    double? latitude,
    double? longitude,
    String langCode = 'en',
  }) async {
    try {
      final double lat;
      final double lon;

      if (latitude != null && longitude != null) {
        lat = latitude;
        lon = longitude;
      } else {
        final coords = await _getCoordinates(locationName);
        lat = coords['lat']!;
        lon = coords['lon']!;
      }

      // 1. Try OpenWeatherMap REST API first if apiKey is available
      if (apiKey.isNotEmpty) {
        try {
          final owmData = await _fetchFromOpenWeather(
            lat: lat,
            lon: lon,
            locationName: locationName,
            cropName: cropName,
            langCode: langCode,
          );
          if (owmData != null) {
            return owmData;
          }
        } catch (_) {}
      }

      // 2. Fallback to Open-Meteo REST API
      final uri = Uri.parse(
        '${ApiConstants.openMeteoForecastUrl}?'
        'latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
        '&timezone=auto',
      );

      final res = await http.get(uri).timeout(ApiConstants.connectTimeout);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final current = data['current'];
        final daily = data['daily'];

        final temp = (current['temperature_2m'] as num).toDouble();
        final humidity = (current['relative_humidity_2m'] as num).toInt();
        final windSpeed = (current['wind_speed_10m'] as num).toDouble();
        final weatherCode = (current['weather_code'] as num).toInt();
        final precipitation = (current['precipitation'] as num).toDouble();

        final condition = _mapWeatherCode(weatherCode);

        // Daily forecast
        final List<DailyForecast> forecastList = [];
        if (daily != null && daily['time'] != null) {
          final times = daily['time'] as List;
          final maxTemps = daily['temperature_2m_max'] as List;
          final minTemps = daily['temperature_2m_min'] as List;
          final prob = daily['precipitation_probability_max'] as List?;
          final codes = daily['weather_code'] as List;

          for (int i = 0; i < times.length && i < 7; i++) {
            forecastList.add(
              DailyForecast(
                date: DateTime.tryParse(times[i]) ?? DateTime.now().add(Duration(days: i)),
                maxTemp: (maxTemps[i] as num).toDouble(),
                minTemp: (minTemps[i] as num).toDouble(),
                condition: _mapWeatherCode((codes[i] as num).toInt()),
                rainProbability: (prob != null && i < prob.length && prob[i] != null)
                    ? (prob[i] as num).toInt()
                    : (precipitation > 0 ? 60 : 15),
              ),
            );
          }
        }

        final rainProb = forecastList.isNotEmpty ? forecastList[0].rainProbability : (precipitation > 0 ? 70 : 20);

        final advisory = generateAdvisoryForLanguage(
          temp: temp,
          humidity: humidity,
          rainProb: rainProb,
          windSpeed: windSpeed,
          cropName: cropName,
          langCode: langCode,
        );

        return WeatherData(
          temperature: temp,
          condition: condition,
          humidity: humidity,
          windSpeed: windSpeed,
          rainProbability: rainProb,
          locationName: locationName,
          forecast: forecastList,
          agriculturalAdvisory: advisory,
        );
      }
    } catch (_) {}

    // Resilient offline realistic data
    return _generateFallbackWeather(locationName, cropName, langCode: langCode);
  }

  String _mapWeatherCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1 || code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain Showers';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Heavy Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Partly Cloudy';
  }

  String generateAdvisoryForLanguage({
    required double temp,
    required int humidity,
    required int rainProb,
    required double windSpeed,
    required String cropName,
    String langCode = 'en',
  }) {
    final buffer = StringBuffer();

    if (langCode == 'ta') {
      if (rainProb >= 50) {
        buffer.writeln('இன்று மழை பெய்ய வாய்ப்பு அதிகம் ($rainProb%). வயலில் தேவையற்ற நீர்ப்பாசனத்தைத் தவிர்க்கவும்.');
        buffer.writeln('முக்கிய அறிவிப்பு: $cropName பயிருக்கு பூச்சிக்கொல்லி மருந்து அல்லது உரமிடுதல் திட்டமிட்டிருந்தால், மழை மருந்தைக் கழுவிவிடக்கூடும் என்பதால் 24-48 மணி நேரம் தள்ளி வைக்கவும்.');
      } else if (temp >= 35) {
        buffer.writeln('அதிக வெப்பநிலை எச்சரிக்கை ($temp°C). $cropName பயிரில் ஈரப்பதம் குறைவதைத் தடுக்க அதிகாலை அல்லது மாலை வேளையில் லேசான நீர்ப்பாசனம் செய்யவும்.');
        buffer.writeln('விவசாயக் குறிப்பு: வேர் மண்டல ஈரப்பதத்தைப் பாதுகாக்க இயற்கை மூடாக்கு (பயிர் கழிவுகள்) இடவும்.');
      } else {
        buffer.writeln('வானிலை வழக்கமான களப்பணிகள், உழவு மற்றும் பயிர் பராமரிப்புக்கு சாதகமாக உள்ளது.');
      }

      if (humidity >= 75) {
        buffer.writeln('அதிக காற்று ஈரப்பதம் ($humidity%) பூஞ்சை நோய்களை (சாம்பல் நோய் மற்றும் இலைக்கருகல்) உருவாக்கலாம். பயிரின் கீழ் இலைகளைத் தீவிரமாகக் கண்காணிக்கவும்.');
      }

      if (windSpeed >= 20) {
        buffer.writeln('வேகமான காற்று வீசுகிறது ($windSpeed கி.மீ/மணி). மருந்து தெளிப்பதைத் தவிர்க்கவும், இல்லையெனில் மருந்து காற்றில் விரயமாகும்.');
      }
    } else if (langCode == 'hi') {
      if (rainProb >= 50) {
        buffer.writeln('बारिश की संभावना अधिक है ($rainProb%)। आज फसलों की अनावश्यक सिंचाई से बचें।');
        buffer.writeln('महत्वपूर्ण सूचना: यदि आपने $cropName पर कीटनाशक या खाद का छिड़काव तय किया है, तो बारिश के कारण दवा धुलने से बचाने के लिए इसे 24-48 घंटे टाल दें।');
      } else if (temp >= 35) {
        buffer.writeln('उच्च तापमान की चेतावनी ($temp°C)। $cropName में नमी बनाए रखने के लिए सुबह या शाम को हल्की सिंचाई करें।');
        buffer.writeln('सलाह: जड़ों में नमी संरक्षण के लिए जैविक मल्चिंग का उपयोग करें।');
      } else {
        buffer.writeln('मौसम सामान्य कृषि कार्यों, निराई-गुड़ाई और कटाई के लिए पूरी तरह अनुकूल है।');
      }

      if (humidity >= 75) {
        buffer.writeln('हवा में उच्च आर्द्रता ($humidity%) से फफूंद जनित रोगों (झुलसा व पाउडरी मिल्ड्यू) का खतरा बढ़ सकता है। निचली पत्तियों की निगरानी करें।');
      }

      if (windSpeed >= 20) {
        buffer.writeln('तेज हवाएं ($windSpeed किमी/घंटा) चल रही हैं। पत्तों पर किसी भी प्रकार के छिड़काव से बचें।');
      }
    } else if (langCode == 'te') {
      if (rainProb >= 50) {
        buffer.writeln('వర్షం కురిసే అవకాశం ఎక్కువగా ఉంది ($rainProb%). ఈ రోజు అనవసరపు నీటిపారుదలని నివారించండి.');
        buffer.writeln('గమనిక: $cropName పై పురుగుమందులు లేదా ఎరువులు పిచికారీ చేయాలనుకుంటే 24-48 గంటలు వాయిదా వేయండి.');
      } else if (temp >= 35) {
        buffer.writeln('అధిక ఉష్ణోగ్రత హెచ్చరిక ($temp°C). తేమ తగ్గకుండా ఉదయం లేదా సాయంత్రం వేళల్లో తేలికపాటి నీరు పెట్టండి.');
      } else {
        buffer.writeln('సాధారణ పంట పనులకు మరియు కోతలకు వాతావరణం అనుకూలంగా ఉంది.');
      }
      if (humidity >= 75) {
        buffer.writeln('అధిక తేమ ($humidity%) వల్ల శిలీంధ్ర వ్యాధులు వచ్చే అవకాశం ఉంది. దిగువ ఆకులను గమనించండి.');
      }
      if (windSpeed >= 20) {
        buffer.writeln('ఈదురు గాలులు ($windSpeed కి.மீ/గం) వీస్తున్నాయి. స్ప్రేయింగ్ చేయవద్దు.');
      }
    } else if (langCode == 'kn') {
      if (rainProb >= 50) {
        buffer.writeln('ಮಳೆಯ ಸಾಧ್ಯತೆ ಹೆಚ್ಚಾಗಿದೆ ($rainProb%). ಇಂದು ಬೆಳೆಗಳಿಗೆ ಅನಗತ್ಯ ನೀರಾವರಿಯನ್ನು ತಪ್ಪಿಸಿ.');
        buffer.writeln('ಸೂಚನೆ: $cropName ಬೆಳೆಗೆ ಕೀಟನಾಶಕ ಸಿಂಪಡಣೆಯನ್ನು 24-48 ಗಂಟೆ ಮುಂದೂಡಿ.');
      } else if (temp >= 35) {
        buffer.writeln('ಹೆಚ್ಚಿನ ತಾಪಮಾನದ ಎಚ್ಚರಿಕೆ ($temp°C). ತೇವಾಂಶ ಕಾಪಾಡಲು ಬೆಳಗಿನ ಜಾವ ಅಥವಾ ಸಂಜೆ ಲಘು ನೀರಾವರಿ ಮಾಡಿ.');
      } else {
        buffer.writeln('ಸಾಮಾನ್ಯ ಕೃಷಿ ಕೆಲಸಗಳಿಗೆ ಹವಾಮಾನ ಅನುಕೂಲಕರವಾಗಿದೆ.');
      }
      if (humidity >= 75) {
        buffer.writeln('ಹೆಚ್ಚಿನ ತೇವಾಂಶ ($humidity%) ಶಿಲೀಂಧ್ರ ರೋಗಗಳಿಗೆ ಕಾರಣವಾಗಬಹುದು. ಎಲೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.');
      }
      if (windSpeed >= 20) {
        buffer.writeln('ವೇಗದ ಗಾಳಿ ($windSpeed km/h) ಬೀಸುತ್ತಿದೆ. ಔಷಧ ಸಿಂಪಡಿಸಬೇಡಿ.');
      }
    } else if (langCode == 'ml') {
      if (rainProb >= 50) {
        buffer.writeln('മഴയ്ക്ക് സാധ്യത കൂടുതലാണ് ($rainProb%). ഇന്ന് അനാവശ്യ ജലസೇചനം ഒഴിവാക്കുക.');
        buffer.writeln('ശ്രദ്ധിക്കുക: $cropName വിളയിൽ കീടനാശിനി പ്രയോഗം 24-48 മണിക്കൂർ മാറ്റിവെക്കുക.');
      } else if (temp >= 35) {
        buffer.writeln('ഉയർന്ന താപനില മുന്നറിയിപ്പ് ($temp°C). ഈർപ്പം നിലനിർത്താൻ അതിരാവിലെയോ വൈകുന്നേരമോ നേരിയ നന നൽകുക.');
      } else {
        buffer.writeln('സാധാരണ കാർഷിക ജോലികൾക്ക് കാലാവസ്ഥ അനുകൂലമാണ്.');
      }
      if (humidity >= 75) {
        buffer.writeln('കൂടിയ ഈർപ്പം ($humidity%) കുമിൾ രോഗങ്ങൾക്ക് കാരണമാകാം. இലകൾ പരിശോധിക്കുക.');
      }
      if (windSpeed >= 20) {
        buffer.writeln('ശക്തമായ കാറ്റ് ($windSpeed km/h) വീശുന്നു. സ്പ്രേ ചെയ്യുന്നത് ഒഴിവാക്കുക.');
      }
    } else {
      // English (default)
      if (rainProb >= 50) {
        buffer.writeln('Rain probability is high ($rainProb%). Avoid unnecessary irrigation today.');
        buffer.writeln('Notice: If you planned pesticide or fertilizer spraying on $cropName, postpone it by 24-48 hours as rainfall will wash away chemicals and reduce efficacy.');
      } else if (temp >= 35) {
        buffer.writeln('High temperature alert ($temp°C). Ensure early morning or late evening light irrigation to prevent moisture stress in $cropName.');
        buffer.writeln('Tip: Apply organic mulch on soil to conserve root zone moisture.');
      } else {
        buffer.writeln('Weather conditions are favorable for regular intercultural operations and harvesting.');
      }

      if (humidity >= 75) {
        buffer.writeln('High atmospheric humidity ($humidity%) increases susceptibility to fungal diseases (mildew & blight). Inspect lower leaves.');
      }

      if (windSpeed >= 20) {
        buffer.writeln('Strong winds detected ($windSpeed km/h). Do not perform foliar dusting or spray operations to prevent chemical drift.');
      }
    }

    return buffer.toString().trim();
  }

  // Generates real weather-based alerts
  List<FarmerAlert> generateWeatherAlerts(WeatherData weather, String cropName) {
    final List<FarmerAlert> alerts = [];

    if (weather.rainProbability >= 60) {
      alerts.add(
        FarmerAlert(
          id: 'alert_rain_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Heavy Rain Alert (${weather.rainProbability}%)',
          description: 'Rain expected in ${weather.locationName}. Avoid scheduled field irrigation and postpone pesticide spraying on $cropName.',
          type: 'weather',
          severity: 'warning',
          timestamp: DateTime.now(),
        ),
      );
    }

    if (weather.temperature >= 36) {
      alerts.add(
        FarmerAlert(
          id: 'alert_temp_${DateTime.now().millisecondsSinceEpoch}',
          title: 'High Temperature Warning (${weather.temperature}°C)',
          description: 'Severe heat stress can cause flower drop in $cropName. Irrigate during cooler evening hours.',
          type: 'weather',
          severity: 'critical',
          timestamp: DateTime.now(),
        ),
      );
    }

    if (weather.humidity >= 80) {
      alerts.add(
        FarmerAlert(
          id: 'alert_humid_${DateTime.now().millisecondsSinceEpoch}',
          title: 'High Humidity Fungal Alert (${weather.humidity}%)',
          description: 'Prolonged leaf wetness promotes early blight and rust in $cropName. Monitor crop closely.',
          type: 'disease',
          severity: 'warning',
          timestamp: DateTime.now(),
        ),
      );
    }

    return alerts;
  }

  WeatherData _generateFallbackWeather(String locationName, String cropName, {String langCode = 'en'}) {
    final now = DateTime.now();
    final forecastList = [
      DailyForecast(date: now, maxTemp: 32.0, minTemp: 24.0, condition: 'Partly Cloudy', rainProbability: 25),
      DailyForecast(date: now.add(const Duration(days: 1)), maxTemp: 31.0, minTemp: 23.5, condition: 'Rain Showers', rainProbability: 65),
      DailyForecast(date: now.add(const Duration(days: 2)), maxTemp: 30.5, minTemp: 23.0, condition: 'Drizzle', rainProbability: 40),
      DailyForecast(date: now.add(const Duration(days: 3)), maxTemp: 32.5, minTemp: 24.0, condition: 'Clear Sky', rainProbability: 10),
      DailyForecast(date: now.add(const Duration(days: 4)), maxTemp: 33.0, minTemp: 24.5, condition: 'Clear Sky', rainProbability: 10),
      DailyForecast(date: now.add(const Duration(days: 5)), maxTemp: 33.5, minTemp: 25.0, condition: 'Partly Cloudy', rainProbability: 20),
      DailyForecast(date: now.add(const Duration(days: 6)), maxTemp: 32.0, minTemp: 24.0, condition: 'Partly Cloudy', rainProbability: 30),
    ];

    final advisory = generateAdvisoryForLanguage(
      temp: 31.5,
      humidity: 72,
      rainProb: 25,
      windSpeed: 14.2,
      cropName: cropName,
      langCode: langCode,
    );

    return WeatherData(
      temperature: 31.5,
      condition: 'Partly Cloudy',
      humidity: 72,
      windSpeed: 14.2,
      rainProbability: 25,
      locationName: locationName,
      forecast: forecastList,
      agriculturalAdvisory: advisory,
    );
  }

  // Fetches live weather and 5-day forecast from OpenWeatherMap REST API
  Future<WeatherData?> _fetchFromOpenWeather({
    required double lat,
    required double lon,
    required String locationName,
    required String cropName,
    String langCode = 'en',
  }) async {
    try {
      final key = apiKey;
      if (key.isEmpty) return null;

      // 1. Current Weather
      final currentUrl = Uri.parse(
        '${ApiConstants.openWeatherMapBaseUrl}/weather?lat=$lat&lon=$lon&appid=$key&units=metric',
      );
      final currentRes = await http.get(currentUrl).timeout(ApiConstants.connectTimeout);
      if (currentRes.statusCode != 200) return null;

      final currentData = json.decode(currentRes.body);
      final main = currentData['main'];
      final wind = currentData['wind'];
      final weatherList = currentData['weather'] as List?;

      final temp = (main['temp'] as num).toDouble();
      final humidity = (main['humidity'] as num).toInt();
      final windSpeed = ((wind != null && wind['speed'] != null)
          ? ((wind['speed'] as num).toDouble() * 3.6) // m/s to km/h
          : 12.0);

      String condition = 'Partly Cloudy';
      if (weatherList != null && weatherList.isNotEmpty) {
        condition = weatherList[0]['main'] ?? 'Partly Cloudy';
      }

      // 2. 5-Day Forecast
      final forecastUrl = Uri.parse(
        '${ApiConstants.openWeatherMapBaseUrl}/forecast?lat=$lat&lon=$lon&appid=$key&units=metric',
      );
      final forecastRes = await http.get(forecastUrl).timeout(ApiConstants.connectTimeout);

      final List<DailyForecast> dailyForecasts = [];
      int currentRainProb = 20;

      if (forecastRes.statusCode == 200) {
        final forecastData = json.decode(forecastRes.body);
        final list = forecastData['list'] as List?;

        if (list != null && list.isNotEmpty) {
          final firstPop = list[0]['pop'];
          if (firstPop is num) {
            currentRainProb = (firstPop * 100).toInt();
          }

          final Map<String, List<Map<String, dynamic>>> dayBuckets = {};
          for (final item in list) {
            final dtTxt = item['dt_txt'] as String?;
            if (dtTxt != null && dtTxt.length >= 10) {
              final dateKey = dtTxt.substring(0, 10);
              dayBuckets.putIfAbsent(dateKey, () => []).add(item);
            }
          }

          dayBuckets.forEach((dateStr, items) {
            if (dailyForecasts.length >= 7) return;

            double maxT = -999.0;
            double minT = 999.0;
            double maxPop = 0.0;
            String dayCond = 'Partly Cloudy';

            for (final slice in items) {
              final m = slice['main'];
              if (m != null) {
                final tMax = (m['temp_max'] as num?)?.toDouble() ?? 0.0;
                final tMin = (m['temp_min'] as num?)?.toDouble() ?? 0.0;
                if (tMax > maxT) maxT = tMax;
                if (tMin < minT) minT = tMin;
              }
              final p = slice['pop'];
              if (p is num && p.toDouble() > maxPop) {
                maxPop = p.toDouble();
              }
              final w = slice['weather'] as List?;
              if (w != null && w.isNotEmpty) {
                final c = w[0]['main'] as String?;
                if (c == 'Rain' || c == 'Thunderstorm') {
                  dayCond = c!;
                } else if (dayCond != 'Rain' && c != null) {
                  dayCond = c;
                }
              }
            }

            final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            dailyForecasts.add(
              DailyForecast(
                date: parsedDate,
                maxTemp: maxT > -999 ? maxT : temp + 2.0,
                minTemp: minT < 999 ? minT : temp - 3.0,
                condition: dayCond,
                rainProbability: (maxPop * 100).toInt(),
              ),
            );
          });
        }
      }

      final advisory = generateAdvisoryForLanguage(
        temp: temp,
        humidity: humidity,
        rainProb: currentRainProb,
        windSpeed: windSpeed,
        cropName: cropName,
        langCode: langCode,
      );

      return WeatherData(
        temperature: temp,
        condition: condition,
        humidity: humidity,
        windSpeed: windSpeed,
        rainProbability: currentRainProb,
        locationName: locationName,
        forecast: dailyForecasts,
        agriculturalAdvisory: advisory,
      );
    } catch (_) {
      return null;
    }
  }
}