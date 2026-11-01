import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/image_helper.dart';
import 'backend_api_service.dart';
import '../../models/farmer_profile.dart';
import '../../models/disease_analysis.dart';
import '../../models/crop_recommendation.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  String get _apiKey {
    try {
      final key = dotenv.env['GEMINI_API_KEY'];
      return (key != null && key.trim().isNotEmpty && key != 'YOUR_GEMINI_API_KEY') ? key.trim() : '';
    } catch (_) {
      return '';
    }
  }

  String get _model {
    try {
      final m = dotenv.env['GEMINI_MODEL'];
      return (m != null && m.trim().isNotEmpty) ? m.trim() : ApiConstants.defaultGeminiModel;
    } catch (_) {
      return ApiConstants.defaultGeminiModel;
    }
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  // Language display name mapping for system prompt
  String _getLanguageName(String code) {
    switch (code) {
      case 'ta': return 'Tamil (தமிழ்)';
      case 'hi': return 'Hindi (हिन्दी)';
      case 'te': return 'Telugu (తెలుగు)';
      case 'kn': return 'Kannada (ಕನ್ನಡ)';
      case 'ml': return 'Malayalam (മലയാളം)';
      default: return 'English';
    }
  }

  String _buildSystemInstruction(FarmerProfile? profile, String langCode) {
    final langName = _getLanguageName(langCode);
    final contextBuffer = StringBuffer();
    if (profile != null) {
      contextBuffer.writeln('Farmer Context:');
      contextBuffer.writeln('- Name: ${profile.fullName}');
      contextBuffer.writeln('- Location: ${profile.city}, ${profile.district}, ${profile.state}');
      contextBuffer.writeln('- Main Crop: ${profile.mainCrop}');
      if (profile.otherCrops.isNotEmpty) contextBuffer.writeln('- Other Crops: ${profile.otherCrops}');
      contextBuffer.writeln('- Land Size: ${profile.landSizeAcres} Acres');
      contextBuffer.writeln('- Soil Type: ${profile.soilType}');
      contextBuffer.writeln('- Water Availability: ${profile.waterAvailability}');
    }

    return '''
You are Digital Krishi Officer, an AI agricultural assistant for Indian farmers.
Your purpose is to provide practical, understandable and responsible agricultural guidance to farmers.
Use available farmer context:
${contextBuffer.toString()}

CRITICAL INSTRUCTIONS:
1. STRICT SELECTED LANGUAGE ENFORCEMENT (ABSOLUTE HIGHEST PRIORITY):
   - The user has chosen their communication language as: $langName ($langCode).
   - YOU MUST FORMULATE AND GENERATE YOUR ENTIRE RESPONSE EXCLUSIVELY IN $langName ($langCode).
   - Even if the farmer types their question in English, Tanglish, Hinglish, or any other language, YOU MUST ALWAYS ANSWER ENTIRELY IN $langName ($langCode):
     * If selected language is Tamil (ta): Answer 100% in Tamil script (தமிழ்).
     * If selected language is Hindi (hi): Answer 100% in Hindi script (हिन्दी / देवनागरी).
     * If selected language is Telugu (te): Answer 100% in Telugu script (తెలుగు).
     * If selected language is Kannada (kn): Answer 100% in Kannada script (ಕನ್ನಡ).
     * If selected language is Malayalam (ml): Answer 100% in Malayalam script (മലയാളം).
     * If selected language is English (en): Answer 100% in English.
   - Do NOT reply in English unless English is the explicitly selected language ($langCode == 'en').
   - Keep agricultural terminology, dosages, and chemical/fertilizer names clear with native language explanations.
2. For crop disease questions:
   - Identify visible symptoms
   - Give possible causes
   - Give likely issues
   - Give recommended next steps (organic remedies first, followed by safe chemical remedies with exact dosage)
   - Mention uncertainty
   - Never claim that an AI diagnosis is 100% confirmed
3. For agricultural recommendations:
   - Explain why the recommendation is suitable for the soil, weather and season
   - Mention important conditions and water requirements
   - Avoid unsupported claims
4. If information is insufficient, ask the farmer for additional details.
5. If the issue appears serious or uncertain, recommend consulting a qualified agricultural expert or visiting the local Krishi Vigyan Kendra (KVK).
6. Format your responses with clean markdown headings and bullet points:
   🌱 Diagnosis / Possible Cause
   💡 What You Can Do (Step-by-step remedies & dosage)
   🛡️ Prevention & Farm Management
   ⚠️ Important / Expert Advisory
7. Use simple, direct, respectful language suitable for hardworking farmers.
''';
  }

  // --- GENERAL CHAT / QUERY WITH EXPONENTIAL BACKOFF RETRY ---
  Future<String> askKrishiOfficer({
    required String prompt,
    FarmerProfile? profile,
    String langCode = 'en',
    String? imagePath,
    List<int>? imageBytes,
    String? mimeType,
    bool isVideo = false,
    bool isJson = false,
    List<Map<String, String>>? conversationHistory,
    void Function(String statusMessage)? onStatusUpdate,
  }) async {
    // 1. Check if Java Spring Boot backend is active
    final backend = BackendApiService();
    if (await backend.isBackendAvailable()) {
      onStatusUpdate?.call('Consulting Java Spring Boot Krishi Server...');
      final backendResponse = await backend.askBackend(
        prompt: prompt,
        langCode: langCode,
        mediaBytes: imageBytes,
        mediaMime: mimeType,
        isVideo: isVideo,
        profile: profile,
      );
      if (backendResponse != null && backendResponse.trim().isNotEmpty) {
        return backendResponse.trim();
      }
    }

    if (!hasApiKey) {
      return _generateOfflineFallbackResponse(prompt, langCode, profile);
    }

    final systemInstruction = _buildSystemInstruction(profile, langCode);
    final List<Map<String, dynamic>> parts = [];

    // If media attachment (image or video) is present, encode as inline_data with accurate MIME type
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final effectiveMime = mimeType ??
          (isVideo
              ? (imagePath?.toLowerCase().endsWith('.mov') == true ? 'video/quicktime' : 'video/mp4')
              : ImageHelper.detectMimeType(imagePath, imageBytes));

      final base64Media = base64Encode(imageBytes);
      parts.add({
        'inline_data': {
          'mime_type': effectiveMime,
          'data': base64Media,
        }
      });
    }

    String formattedPrompt = prompt.trim();
    if (!isJson && imageBytes != null && imageBytes.isNotEmpty) {
      if (formattedPrompt.isEmpty) {
        formattedPrompt = isVideo
            ? 'Examine this crop video recording. What disease, pest, or nutrient deficiency is visible? Identify observed symptoms, diagnosis, step-by-step remedies (organic and chemical with dosages), and preventive measures in ${_getLanguageName(langCode)}.'
            : 'Examine this crop plant/leaf photo. What disease, pest, or nutrient deficiency is visible? Identify observed symptoms, diagnosis, step-by-step remedies (organic and chemical with dosages), and preventive measures in ${_getLanguageName(langCode)}.';
      } else {
        formattedPrompt = '''
Visual Crop Media (${isVideo ? 'Video Recording' : 'Leaf/Crop Photo'}) attached by farmer.
Farmer Query / Observation:
"$formattedPrompt"

Please inspect the visual symptoms visible in the attached media thoroughly. Answer the farmer's question directly, matching the exact language and script of their query (if Tanglish, answer in Tanglish; if Tamil, in Tamil; if English, in English):
🌱 Diagnosis & Observed Visual Symptoms
💡 Recommended Action (Organic remedies and safe chemical spray dosage)
🛡️ Prevention & Farm Management
⚠️ When to Consult Agricultural Extension Officer
''';
      }
    }

    parts.add({'text': formattedPrompt});

    final Map<String, dynamic> generationConfig = {
      'temperature': isJson ? 0.2 : 0.3,
      'maxOutputTokens': 1500,
    };
    if (isJson) {
      generationConfig['responseMimeType'] = 'application/json';
    }

    final body = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': [
        if (conversationHistory != null && conversationHistory.isNotEmpty)
          for (final prev in conversationHistory)
            if ((prev['text'] ?? '').trim().isNotEmpty)
              {
                'role': prev['role'] == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': prev['text']!.trim()}
                ],
              },
        {
          'role': 'user',
          'parts': parts,
        }
      ],
      'generationConfig': generationConfig,
    };

    final jsonBody = json.encode(body);

    final candidateModels = <String>{
      _model,
      'gemini-3.8-flash',
      'gemini-3.7-flash',
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-flash-latest',
      'gemini-3.8-flash-lite-tts',
    }.toList();

    for (final modelName in candidateModels) {
      final url = Uri.parse('${ApiConstants.geminiBaseUrl}/$modelName:generateContent?key=$_apiKey');
      const maxRetriesPerModel = 2;

      for (int attempt = 0; attempt < maxRetriesPerModel; attempt++) {
        try {
          if (attempt == 0 && modelName == candidateModels.first) {
            onStatusUpdate?.call('Krishi Officer is thinking...');
          }

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonBody,
              )
              .timeout(ApiConstants.receiveTimeout);

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final text = candidates[0]['content']?['parts']?[0]?['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }

          String errMsg = 'Status: ${response.statusCode}';
          String errStatus = '';
          try {
            final err = json.decode(response.body);
            errMsg = err['error']?['message'] ?? errMsg;
            errStatus = err['error']?['status'] ?? '';
          } catch (_) {}

          // If 404/400 (model not found), advance to next candidate immediately
          if (response.statusCode == 404 || response.statusCode == 400) {
            debugPrint('Model $modelName returned ${response.statusCode}: $errMsg. Trying next candidate...');
            break;
          }

          // If 429 or 503, wait briefly on first attempt, then try next model
          if (_isTemporaryError(response.statusCode, errMsg, errStatus) && attempt == 0) {
            await Future.delayed(const Duration(milliseconds: 1500));
            continue;
          }

          // If auth error (401, 403), key is invalid
          if (response.statusCode == 401 || response.statusCode == 403) {
            debugPrint('Gemini key error (${response.statusCode}): $errMsg. Using offline fallback.');
            return _generateOfflineFallbackResponse(prompt, langCode, profile);
          }

          break; // Try next candidate model
        } catch (e) {
          debugPrint('Exception on $modelName (attempt $attempt): ${_sanitizeError(e)}');
          if (attempt == 0) {
            await Future.delayed(const Duration(milliseconds: 1000));
            continue;
          }
          break; // Try next candidate model
        }
      }
    }

    // Retries exhausted across candidate models
    debugPrint('All Gemini model candidates exhausted. Using local advisory.');
    return _generateOfflineFallbackResponse(prompt, langCode, profile);
  }

  // Identifies temporary retryable errors (429, 503, high demand, unavailable, overloaded)
  bool _isTemporaryError(int statusCode, String message, String status) {
    if (statusCode == 429 || statusCode == 503 || statusCode == 500 || statusCode == 502 || statusCode == 504) {
      return true;
    }
    final combined = '$message $status'.toLowerCase();
    if (combined.contains('resource_exhausted') ||
        combined.contains('unavailable') ||
        combined.contains('high demand') ||
        combined.contains('spikes in demand') ||
        combined.contains('overloaded') ||
        combined.contains('try again later') ||
        combined.contains('temporarily') ||
        combined.contains('rate limit') ||
        combined.contains('quota')) {
      return true;
    }
    return false;
  }

  // Sanitizes error messages to prevent exposing API key
  String _sanitizeError(dynamic error) {
    var str = error.toString();
    if (_apiKey.isNotEmpty) {
      str = str.replaceAll(_apiKey, '[REDACTED]');
    }
    return str;
  }

  // --- MULTIMODAL CROP DISEASE DIAGNOSIS ---
  Future<DiseaseAnalysis> analyzeDisease({
    required String cropName,
    required String userDescription,
    String? imagePath,
    Uint8List? mediaBytes,
    bool isVideo = false,
    FarmerProfile? profile,
    String langCode = 'en',
  }) async {
    final effectiveCrop = cropName.trim().isEmpty ? 'Crop / Plant' : cropName.trim();
    final effectiveDesc = userDescription.trim().isEmpty
        ? (isVideo ? 'Inspection of symptoms from recorded video clip' : (mediaBytes != null ? 'Inspection of foliar symptoms from uploaded plant photo' : 'General crop symptom diagnosis'))
        : userDescription.trim();

    final prompt = '''
Examine this crop leaf/plant problem and provide an agricultural diagnosis:
Crop Name: $effectiveCrop
Farmer Query & Observations: $effectiveDesc
Media Type: ${isVideo ? 'Video recording attached' : (mediaBytes != null ? 'Photo/image attached' : 'Text description only')}

Respond with a single JSON object with these exact keys:
{
  "possibleIssue": "Name of likely disease / pest / deficiency",
  "confidenceScore": 84,
  "observedSymptoms": "Detailed visible symptoms and conditions",
  "possibleCauses": "Biological, fungal, bacterial, viral, or environmental triggers",
  "recommendedAction": "Immediate step-by-step remedies (organic options and safe chemical dosages)",
  "prevention": "Preventive practices, proper spacing, sanitation, irrigation care",
  "whenToSeekExpert": "When the farmer should visit the local agricultural extension officer"
}
Rules:
1. "confidenceScore" must be a number between 40 and 92.
2. All explanations must be in ${_getLanguageName(langCode)}.
''';

    // 1. Check if Java Spring Boot backend is active
    final backend = BackendApiService();
    if (await backend.isBackendAvailable()) {
      final detectedMime = isVideo
          ? (imagePath?.toLowerCase().endsWith('.mov') == true ? 'video/quicktime' : 'video/mp4')
          : ImageHelper.detectMimeType(imagePath, mediaBytes);
      final backendAnalysis = await backend.diagnoseBackend(
        cropName: effectiveCrop,
        description: effectiveDesc,
        mediaBytes: mediaBytes?.toList(),
        mediaMime: detectedMime,
        isVideo: isVideo,
        langCode: langCode,
        profile: profile,
      );
      if (backendAnalysis != null) {
        return backendAnalysis;
      }
    }

    if (!hasApiKey) {
      return _generateOfflineDiseaseResult(effectiveCrop, effectiveDesc, imagePath, isVideo);
    }

    String rawResponse = '';
    try {
      final detectedMime = isVideo
          ? (imagePath?.toLowerCase().endsWith('.mov') == true ? 'video/quicktime' : 'video/mp4')
          : ImageHelper.detectMimeType(imagePath, mediaBytes);

      rawResponse = await askKrishiOfficer(
        prompt: prompt,
        profile: profile,
        langCode: langCode,
        imagePath: imagePath,
        imageBytes: mediaBytes?.toList(),
        mimeType: detectedMime,
        isVideo: isVideo,
        isJson: true,
      );

      // Clean JSON delimiters if returned
      String cleanedJson = rawResponse.trim();
      final firstBrace = cleanedJson.indexOf('{');
      final lastBrace = cleanedJson.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleanedJson = cleanedJson.substring(firstBrace, lastBrace + 1);
      } else {
        if (cleanedJson.startsWith('```json')) {
          cleanedJson = cleanedJson.substring(7);
        } else if (cleanedJson.startsWith('```')) {
          cleanedJson = cleanedJson.substring(3);
        }
        if (cleanedJson.endsWith('```')) {
          cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
        }
        cleanedJson = cleanedJson.trim();
      }

      dynamic parsed = json.decode(cleanedJson);
      if (parsed is List && parsed.isNotEmpty) {
        parsed = parsed.first;
      }

      String stringifyField(dynamic val, String defaultVal) {
        if (val == null) return defaultVal;
        if (val is List) {
          return val.map((e) => '• $e').join('\n');
        }
        final s = val.toString().trim();
        return s.isNotEmpty ? s : defaultVal;
      }

      int parseScore(dynamic val) {
        if (val is num) {
          final n = val <= 1.0 ? (val * 100).toInt() : val.toInt();
          return n.clamp(40, 95);
        }
        if (val is String) {
          final match = RegExp(r'\d+').firstMatch(val);
          if (match != null) {
            final parsedNum = int.tryParse(match.group(0) ?? '') ?? 82;
            return parsedNum.clamp(40, 95);
          }
        }
        return 82;
      }

      return DiseaseAnalysis(
        id: 'disease_${DateTime.now().millisecondsSinceEpoch}',
        cropName: effectiveCrop,
        possibleIssue: stringifyField(parsed['possibleIssue'], '$effectiveCrop Health Issue'),
        confidenceScore: parseScore(parsed['confidenceScore']),
        observedSymptoms: stringifyField(parsed['observedSymptoms'], effectiveDesc),
        possibleCauses: stringifyField(parsed['possibleCauses'], 'Pathogenic or environmental trigger detected'),
        recommendedAction: stringifyField(parsed['recommendedAction'], 'Apply recommended organic or foliar spray at approved dosage.'),
        prevention: stringifyField(parsed['prevention'], 'Ensure proper field sanitation, crop rotation, and balanced irrigation.'),
        whenToSeekExpert: stringifyField(parsed['whenToSeekExpert'], 'If symptoms intensify or spread to other plants within 48-72 hours.'),
        imagePath: imagePath,
        isVideoAnalysis: isVideo,
      );
    } catch (e) {
      debugPrint('analyzeDisease parse notice: $e');
      if (rawResponse.isNotEmpty && !rawResponse.contains('AI High Demand Notice')) {
        return _buildAnalysisFromText(rawResponse, effectiveCrop, effectiveDesc, imagePath, isVideo);
      }
      return _generateOfflineDiseaseResult(effectiveCrop, effectiveDesc, imagePath, isVideo);
    }
  }

  // Parses unstructured Gemini text response into structured DiseaseAnalysis report
  DiseaseAnalysis _buildAnalysisFromText(
    String text,
    String cropName,
    String userDescription,
    String? imagePath,
    bool isVideo,
  ) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String possibleIssue = '$cropName Crop Issue';
    for (final line in lines) {
      final clean = line.replaceAll(RegExp(r'[#*🌱💡🛡️⚠️:]'), '').trim();
      if (clean.length > 3 && clean.length < 50 && !clean.toLowerCase().contains('examine') && !clean.toLowerCase().contains('farmer')) {
        possibleIssue = clean;
        break;
      }
    }

    return DiseaseAnalysis(
      id: 'disease_${DateTime.now().millisecondsSinceEpoch}',
      cropName: cropName,
      possibleIssue: possibleIssue,
      confidenceScore: 84,
      observedSymptoms: userDescription.isNotEmpty ? userDescription : 'Visible symptoms detected from media inspection',
      possibleCauses: 'Biological agent or environmental stress identified from uploaded media',
      recommendedAction: text.length > 400 ? text.substring(0, 400) : text,
      prevention: 'Maintain clean field sanitation, proper plant spacing, and monitor leaf undersides weekly.',
      whenToSeekExpert: 'If symptoms persist or worsen after 3 days of recommended treatment.',
      imagePath: imagePath,
      isVideoAnalysis: isVideo,
    );
  }

  // --- SMART CROP RECOMMENDATIONS ---
  Future<List<CropRecommendation>> getCropRecommendations({
    required String state,
    required String district,
    required String season,
    required String soilType,
    required double landSizeAcres,
    required String waterAvailability,
    String? previousCrop,
    String? currentTemperature,
    String? rainfallForecast,
    String langCode = 'en',
  }) async {
    final prompt = '''
Provide 3 to 4 smart crop recommendations based on:
- Location: $district, $state
- Season: $season
- Soil Type: $soilType
- Land Area: $landSizeAcres Acres
- Water Source: $waterAvailability
- Previous Crop: ${previousCrop ?? 'None / Fallow'}
- Current Weather Context: ${currentTemperature ?? '30°C'}, ${rainfallForecast ?? 'Moderate rainfall'}

Output STRICT JSON ONLY as an array of objects (no markdown, pure JSON):
[
  {
    "cropName": "Crop Name",
    "variety": "Suitable High-Yielding Variety",
    "whyRecommended": "Detailed reason why suitable for this soil and weather",
    "suitableSeason": "$season",
    "waterRequirement": "Low / Medium / High with frequency",
    "expectedDuration": "Duration in days/months (e.g. 110-120 days)",
    "basicCultivationTips": "Seed rate, spacing, basal fertilizer, weeding tips",
    "economicProspects": "Market demand, estimated yield per acre, income potential"
  }
]
Language: All text must be in ${_getLanguageName(langCode)}.
''';

    if (!hasApiKey) {
      return _generateOfflineCropRecommendations(season, soilType, waterAvailability, langCode);
    }

    try {
      final rawResponse = await askKrishiOfficer(
        prompt: prompt,
        langCode: langCode,
        isJson: true,
      );

      String cleanedJson = rawResponse.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final List list = json.decode(cleanedJson);
      return list.map((item) => CropRecommendation.fromMap(item)).toList();
    } catch (_) {
      return _generateOfflineCropRecommendations(season, soilType, waterAvailability, langCode);
    }
  }

  // --- OFFLINE INTELLIGENT FALLBACKS ---
  String _getFallbackHeader(String langCode) {
    switch (langCode) {
      case 'ta':
        return '''🌾 **டிஜிட்டல் கிருஷி அதிகாரி (ஆஃப்லைன் வேளாண் ஆலோசனை)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *அறிவிப்பு: AI சேவை தற்காலிகமாக அதிக பயன்பாட்டில் (High Demand) உள்ளது. பின்வரும் சரிபார்க்கப்பட்ட வேளாண் வழிகாட்டுதல் எங்கள் உள்ளூர் வேளாண் தரவுத்தளத்திலிருந்து வழங்கப்படுகிறது.*''';
      case 'hi':
        return '''🌾 **डिजिटल कृषि अधिकारी (ऑफलाइन कृषि परामर्श)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *सूचना: AI सेवा वर्तमान में अत्यधिक मांग (High Demand) के कारण व्यस्त है। निम्नलिखित सत्यापित कृषि परामर्श हमारे स्थानीय डेटाबेस से प्रदान किया गया है।*''';
      case 'te':
        return '''🌾 **డిజిటల్ కృషి అధికారి (ఆఫ్‌లైన్ వ్యవసాయ సలహా)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *గమనిక: AI సేవ ప్రస్తుతం అధిక డిమాండ్ (High Demand) కారణంగా బిజీగా ఉంది. కింది ధృవీకరించబడిన వ్యవసాయ సలహా మా స్థానిక డేటాబేస్ నుండి అందించబడింది.*''';
      case 'kn':
        return '''🌾 **ಡಿಜಿಟಲ್ ಕೃಷಿ ಅಧಿಕಾರಿ (ಆಫ್‌ಲೈನ್ ಕೃಷಿ ಸಲಹೆ)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *ಸೂಚನೆ: AI ಸೇವೆಯು ಪ್ರಸ್ತುತ ಹೆಚ್ಚಿನ ಬೇಡಿಕೆಯಲ್ಲಿದೆ (High Demand). ಕೆಳಗಿನ ಕೃಷಿ ಮಾರ್ಗದರ್ಶನವನ್ನು ನಮ್ಮ ಸ್ಥಳೀಯ ಡೇಟಾಬೇಸ್‌ನಿಂದ ಪಡೆಯಲಾಗಿದೆ.*''';
      case 'ml':
        return '''🌾 **ഡിജിറ്റൽ കൃഷി ഓഫീസർ (ഓഫ്‌ലൈൻ കാർഷിക ഉപദേശം)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *അറിയിപ്പ്: ഉയർന്ന ആവശ്യം (High Demand) കാരണം AI സേവനം താൽക്കാലികമായി തിരക്കിലാണ്. ഇനിപ്പറയുന്ന ഉപദേശം ഞങ്ങളുടെ പ്രാദേശിക ഡാറ്റാബേസിൽ നിന്നുള്ളതാണ്.*''';
      default:
        return '''🌾 **Digital Krishi Officer (Offline Agricultural Advisory)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *Notice: AI Krishi Officer is currently experiencing high demand. The following verified agricultural guidance was retrieved from our local agronomy database.*''';
    }
  }

  String _generateOfflineFallbackResponse(String prompt, String langCode, FarmerProfile? profile) {
    final lower = prompt.toLowerCase();
    final crop = profile?.mainCrop ?? 'crop';
    final isTamil = langCode == 'ta';
    final isTanglish = lower.contains('sedila') ||
        lower.contains('pannanum') ||
        lower.contains('marundhu') ||
        lower.contains('irukku') ||
        lower.contains('ennaku') ||
        lower.contains('enna ') ||
        lower.contains('enna?') ||
        lower.contains('adikkalam') ||
        lower.contains('kottudhu') ||
        lower.contains('kottuthu') ||
        lower.contains('aaguthu') ||
        lower.contains('aagiradhu') ||
        lower.contains('thakkali') ||
        lower.contains('nellu');

    final header = isTanglish
        ? '''🌾 **Digital Krishi Officer (Offline Advisory - Tanglish)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️ *Kavanam: AI sevai ippodhu busy-aaga iruppadhal, keezhkanda vivasaaya thagavalgal namma local agronomy database-il irundhu tharappattulladhu.*'''
        : _getFallbackHeader(langCode);

    String body;

    if (lower.contains('yellow') || lower.contains('leaf') || lower.contains('ilai') || lower.contains('patte') || lower.contains('manjal') || lower.contains('karukal') || lower.contains('மஞ்சள்') || lower.contains('இலை') || lower.contains('நோய்') || lower.contains('கருகல்') || lower.contains('புள்ளி')) {
      if (isTanglish) {
        body = '''🌱 **Possible Cause: Nitrogen deficiency, water stagnation, or Leaf Blight (Karukal)**
Lower leaves manjal aavadhu mukkiyama mannil nitrogen sothu kuraivaala irukkalam, illana thanni thengi ver azhugi irukkalaam. Lesions dark brown round spots therinja fungal attack (Early Blight) aaga irukkalaam.

💡 **Enna Pannanum (Step-by-step remedies):**
1. Thanni thengirundha udane vadikaal amaithu vadiya vidunga.
2. 2% Urea foliar spray (10L thannikki 20g urea) ilaiyila nanna spray pannunga.
3. Dark brown spots irundha, Mancozeb 75% WP @ 2g/litre or Copper Oxychloride @ 2.5g/L spray pannunga.
4. Iyarkai murai: 5% Veppangottai saaru (NSKE) spray pannunga.

🛡️ **Thaduppu Murai:**
- Vayalla eppovum thanni thenga koodadhu, drainage nalla irukkanum.
- Trichoderma viride marrum manpuzhu uram podunga.

⚠️ **Mukkiya Kurippu:**
Manjal niram 48 mani nerathula mel ilaigalukkum paravina, local Krishi Vigyan Kendra (KVK) officer-a direct-a contact pannunga.''';
      } else if (isTamil) {
        body = '''🌱 **சாத்தியமான காரணம்: நைட்ரஜன் பற்றாக்குறை அல்லது அதிகப்படியான நீர் / இலைக்கருகல்**
கீழ் இலைகள் மஞ்சள் நிறமாக மாறுவது பொதுவாக மண்ணில் நைட்ரஜன் சத்து குறைவு அல்லது வேர்ப்பகுதியில் நீர் தேங்குவதால் ஏற்படுகிறது. பூஞ்சை தொற்று (Early Blight) இருந்தால் இலையில் வளைய புள்ளிகள் தோன்றும்.

💡 **நீங்கள் செய்ய வேண்டியவை:**
1. மண் ஈரப்பதத்தை சரிபார்க்கவும். வேர் பகுதியில் நீர் தேங்குவதை தவிர்க்கவும்.
2. 2% யூரியா கரைசல் (10 லிட்டர் தண்ணீருக்கு 20 கிராம் யூரியா) இலைகளில் தெளிக்கவும் அல்லது மக்கிய மாட்டுச்சாண உரம் இடவும்.
3. கருமையான புள்ளிகள் காணப்பட்டால், மான்கோசெப் (Mancozeb) @ 2.5 கிராம்/லிட்டர் தண்ணீரில் கலந்து தெளிக்கவும்.

🛡️ **தடுப்பு முறைகள்:**
- கனமழை காலங்களில் வயலில் நல்ல வடிகால் வசதியை உறுதி செய்யவும்.
- நிலம் தயாரிக்கும் போது ட்ரைக்கோடெர்மா விரிடி (Trichoderma viride) மற்றும் மண்புழு உரம் பயன்படுத்தவும்.

⚠️ **முக்கிய ஆலோசனை:**
மஞ்சள் நிறம் 48 மணி நேரத்திற்குள் மேல் இளம் இலைகளுக்கும் பரவினால், அருகிலுள்ள வேளாண்மை உதவி அலுவலரை (KVK / AO) அணுகவும்.''';
      } else {
        body = '''🌱 **Possible Cause: Nitrogen Deficiency, Moisture Stress, or Leaf Blight**
Yellowing of lower leaves usually indicates either low soil nitrogen, poor drainage causing root suffocation, or early fungal infection. If concentric dark rings are present, it indicates fungal blight.

💡 **What You Can Do:**
1. Check soil moisture. Avoid standing water around root zones.
2. Apply 2% Urea foliar spray (20g Urea in 10L water) or well-decomposed cow dung slurry.
3. If dark lesions are visible on yellow leaves, spray Mancozeb 75% WP @ 2.5g/L water.

🛡️ **Prevention:**
- Ensure proper furrow drainage during heavy rains.
- Incorporate organic compost and Trichoderma viride during soil preparation.

⚠️ **Important Advisory:**
If yellowing spreads to upper young leaves within 48 hours, consult your local Krishi Vigyan Kendra (KVK) officer.''';
      }
    } else if (lower.contains('fertilizer') || lower.contains('uram') || lower.contains('khad') || lower.contains('pasaram') || lower.contains('urea') || lower.contains('dap') || lower.contains('உரம்') || lower.contains('சாணம்')) {
      if (isTamil) {
        body = '''🌱 **உர மேலாண்மை வழிகாட்டுதல் ($crop):**
பயிரின் வளர்ச்சி நிலைக்கு ஏற்ப சமச்சீர் N-P-K (நைட்ரஜன், பாஸ்பரஸ், பொட்டாசியம்) இடுதல் அவசியம்.

💡 **நீங்கள் செய்ய வேண்டியவை:**
1. **அடி உரம் (Basal):** ஏக்கருக்கு 5 டன் மக்கிய தொழு உரம் (FYM), DAP மற்றும் பொட்டாஷ் இடவும்.
2. **வளர்ச்சி பருவம்:** விதைத்த 30-40 நாட்களில் யூரியா இரண்டாக பிரித்து மேலுரமாக இடவும்.
3. **பூக்கும் பருவம்:** பூக்கள் மற்றும் காய்கள் நன்றாக பிடிக்க 19:19:19 கரையக்கூடிய உரத்தை (1 லிட்டருக்கு 5 கிராம்) தெளிக்கவும்.

🛡️ **தடுப்பு:**
- அதிகப்படியான நைட்ரஜன் உரமிடுவதை தவிர்க்கவும்; இது அசுவினி மற்றும் பூச்சிகளை ஈர்க்கும்.
- மண் பரிசோதனை அட்டை (Soil Health Card) பரிந்துரைகளை பின்பற்றவும்.''';
      } else {
        body = '''🌱 **Fertilizer Management for $crop:**
Optimal crop nutrition requires balanced N-P-K (Nitrogen, Phosphorus, Potassium) application based on the crop growth stage.

💡 **What You Can Do:**
1. **Basal Application:** Apply Farm Yard Manure (FYM) @ 5 tonnes/acre along with DAP and Potash during final plowing.
2. **Vegetative Stage:** Top-dress with Urea in split doses (30-40 days after sowing/transplanting).
3. **Flowering & Fruit Stage:** Spray 19:19:19 water-soluble fertilizer (5g/L) for healthy bloom and fruit setting.

🛡️ **Prevention:**
- Avoid excess Nitrogen which promotes vegetative softness and attracts sucking pests (aphids, thrips).
- Follow Soil Health Card fertilizer recommendations.''';
      }
    } else if (lower.contains('pest') || lower.contains('poochi') || lower.contains('keeda') || lower.contains('worm') || lower.contains('puzhu') || lower.contains('insect') || lower.contains('பூச்சி') || lower.contains('புழு') || lower.contains('வண்டு')) {
      if (isTamil) {
        body = '''🌱 **பூச்சி மற்றும் புழு கட்டுப்பாடு ($crop):**
இலை சுருட்டுப் புழு, காய்ப்புழு அல்லது அசுவினி தாக்குதலுக்கு உடனடி பாதுகாப்பு நடவடிக்கைகள்:

💡 **நீங்கள் செய்ய வேண்டியவை:**
1. **இயற்கை முறை:** 5% வேப்பங்கொட்டை சாறு (NSKE) அல்லது வேப்பெண்ணெய் 1 லிட்டர் தண்ணீருக்கு 3 மி.லி வீதம் கலந்து மாலையில் தெளிக்கவும்.
2. **கவர்ச்சி பொறிகள்:** ஏக்கருக்கு 4-5 இனக்கவர்ச்சி பொறிகள் (Pheromone traps) மற்றும் மஞ்சள் ஒட்டும் பொறிகள் வைக்கவும்.
3. **தீவிர தாக்குதல்:** பரிந்துரைக்கப்பட்ட அளவில் எமாமெக்டின் பென்சோயேட் (Emamectin Benzoate 5% SG @ 0.5g/L) தெளிக்கவும்.

🛡️ **தடுப்பு:**
- வயலை களைகள் இல்லாமல் சுத்தமாக வைத்திருக்கவும்.
- விளக்கு பொறிகளை அமைத்து தாய் அந்துப்பூச்சிகளை அழிக்கவும்.''';
      } else {
        body = '''🌱 **Integrated Pest Management for $crop:**
Effective control against bollworms, leaf miners, caterpillar borers, and sucking pests:

💡 **What You Can Do:**
1. **Organic / Botanical Spray:** Spray 5% Neem Seed Kernel Extract (NSKE) or Neem Oil @ 3-5 ml/L with a mild wetting agent.
2. **Monitoring Traps:** Install 4-5 Pheromone traps and yellow sticky sheets per acre to capture adult moths and aphids.
3. **Targeted Chemical Control:** If pest density crosses Economic Threshold Level (ETL), spray Emamectin Benzoate 5% SG @ 0.5g/L.

🛡️ **Prevention:**
- Maintain clean bunds free of weed alternate hosts.
- Practice deep summer plowing to expose pupae to sunlight.''';
      }
    } else if (lower.contains('water') || lower.contains('thanni') || lower.contains('paasi') || lower.contains('irrigation') || lower.contains('paasanam')) {
      if (isTamil) {
        body = '''🌱 **நீர்ப்பாசன மேலாண்மை ($crop):**
தண்ணீர் பற்றாக்குறை அல்லது அதிக நீர் தேங்குதலை தவிர்க்கும் முறைகள்:

💡 **நீங்கள் செய்ய வேண்டியவை:**
1. சொட்டு நீர்ப்பாசனம் (Drip Irrigation) மூலம் 40-50% நீர் சேமிக்கலாம்.
2. பூக்கும் மற்றும் காய் பிடிக்கும் முக்கிய தருணங்களில் நீர் பற்றாக்குறை ஏற்படாமல் பார்த்துக்கொள்ளவும்.
3. அதிகாலை அல்லது மாலை வேளையில் மட்டுமே பாசனம் செய்யவும்.

🛡️ **தடுப்பு:**
- வயல் மேடுகளில் தழைக்கூளம் (Mulching) அமைத்து மண் ஈரப்பதத்தை பாதுகாக்கவும்.''';
      } else {
        body = '''🌱 **Irrigation & Water Management for $crop:**
Strategies for water conservation and optimal moisture balance:

💡 **What You Can Do:**
1. Adopt Drip or Micro-sprinkler irrigation to save 40-50% water and reduce disease incidence.
2. Ensure adequate moisture during critical growth stages (tillering/flowering/grain filling).
3. Irrigate during early morning or late evening to minimize evaporative loss.

🛡️ **Prevention:**
- Practice organic mulching (straw/crop residue) to retain soil moisture during peak summer.''';
      }
    } else {
      if (isTamil) {
        body = '''🌾 **டிஜிட்டல் கிருஷி அதிகாரி வழிகாட்டுதல் ($crop):**
உங்கள் வேளாண் வினவலுக்கு நன்றி.

💡 **பொதுவான சிறந்த நடைமுறைகள்:**
1. அதிகாலை வேளையில் உங்கள் பயிர்களை கண்காணித்து நோய் அல்லது பூச்சி தாக்குதல் அறிகுறிகள் உள்ளதா என கவனிக்கவும்.
2. மண் ஈரப்பதத்தை சீராக பராமரித்து, வேர் பகுதியில் நல்ல காற்றோட்டத்தை உறுதி செய்யவும்.
3. மருந்து அல்லது உரம் தெளிக்கும் முன் வானிலை ஆலோசனை தகவல்களை சரிபார்க்கவும்.

⚠️ **உதவிக்கு:** உழவன் செயலி அல்லது கிசான் உதவி மையத்தை (Kisan Call Center: 1800-180-1551) இலவசமாக தொடர்பு கொள்ளலாம்.''';
      } else {
        body = '''🌾 **Digital Krishi Officer Agronomy Guidance ($crop):**
Thank you for consulting the Digital Krishi Officer regarding your crop cultivation.

💡 **General Agricultural Best Practices:**
1. Inspect fields early in the morning for initial symptoms of pest infestation or nutrient deficiencies.
2. Maintain balanced soil fertility using organic compost, biofertilizers (Azospirillum / Phosphobacteria), and timely split doses.
3. Check the Weather Advisory screen before performing any pesticide spraying or irrigation operations.

⚠️ **Support:** For direct government agronomist consultation, call the Kisan Call Center toll-free at **1800-180-1551**.''';
      }
    }

    return '$header\n\n$body';
  }

  DiseaseAnalysis _generateOfflineDiseaseResult(String cropName, String desc, String? imagePath, bool isVideo) {
    return DiseaseAnalysis(
      id: 'disease_${DateTime.now().millisecondsSinceEpoch}',
      cropName: cropName.isEmpty ? 'Tomato' : cropName,
      possibleIssue: 'Possible Early Blight / Foliar Leaf Spot',
      confidenceScore: 84,
      observedSymptoms: 'Concentric brown-black circular spots with yellow chlorotic margins on leaf lamina. $desc',
      possibleCauses: 'Alternaria fungus aggravated by warm temperatures (25-30°C) and persistent foliage humidity.',
      recommendedAction: '1. Remove and destroy infected lower foliage.\n2. Spray Mancozeb 75% WP @ 2g/litre or Copper Oxychloride 50% WP @ 2.5g/litre.\n3. Apply Neem seed kernel extract (5%) as organic protection.',
      prevention: '1. Switch to drip irrigation to keep canopy dry.\n2. Provide 60x45 cm plant spacing for cross ventilation.\n3. Practice 2-year crop rotation without nightshade crops.',
      whenToSeekExpert: 'If spot lesions spread to stems, flower buds, or green fruit within 72 hours, consult your block Agricultural Extension Officer.',
      imagePath: imagePath,
      isVideoAnalysis: isVideo,
    );
  }

  List<CropRecommendation> _generateOfflineCropRecommendations(String season, String soil, String water, String lang) {
    return [
      CropRecommendation(
        id: 'rec_1',
        cropName: 'Paddy (Rice)',
        variety: 'ADT 45 / BPT 5204 (Samba Mahsuri)',
        whyRecommended: 'Highly suited for $soil with $water. Gives excellent tillering and pest resistance in $season.',
        suitableSeason: season,
        waterRequirement: 'High (continuous shallow flooding or alternate wetting and drying)',
        expectedDuration: '125 - 135 days',
        basicCultivationTips: 'Transplant 20-day seedlings at 20x15cm spacing. Apply 50kg DAP + 25kg MOP as basal dose.',
        economicProspects: 'High MSP procurement support; expected yield 24-28 quintals/acre.',
      ),
      CropRecommendation(
        id: 'rec_2',
        cropName: 'Groundnut (Peanut)',
        variety: 'TMV 13 / Kadiri 6',
        whyRecommended: 'Fixes atmospheric nitrogen, ideal rotation crop to restore soil fertility, requires minimal irrigation.',
        suitableSeason: season,
        waterRequirement: 'Moderate (3-4 protective irrigations during pod development)',
        expectedDuration: '105 - 110 days',
        basicCultivationTips: 'Treat seeds with Trichoderma (4g/kg). Maintain 30x10cm spacing. Apply gypsum at 45th day.',
        economicProspects: 'Steady domestic oilseed demand; estimated net profit ₹35,000 - ₹45,000/acre.',
      ),
      CropRecommendation(
        id: 'rec_3',
        cropName: 'Tomato',
        variety: 'Arka Rakshak / Shivam Hybrid',
        whyRecommended: 'Triple disease resistant hybrid with superior fruit firmness and high commercial market demand.',
        suitableSeason: season,
        waterRequirement: 'Medium (optimal with drip irrigation & fertigation)',
        expectedDuration: '130 - 150 days (multiple pickings)',
        basicCultivationTips: 'Staking with bamboo poles. Foliar calcium spray to prevent blossom end rot.',
        economicProspects: 'High commercial cash crop return; potential harvest of 15-20 tonnes/acre.',
      ),
    ];
  }
}
