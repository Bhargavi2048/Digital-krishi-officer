import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String _currentSpeakingText = '';

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> currentTextNotifier = ValueNotifier<String>('');
  VoidCallback? onCompletion;

  bool get isPlaying => _isPlaying;
  String get currentSpeakingText => _currentSpeakingText;

  Future<void> init() async {
    try {
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        isPlayingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _currentSpeakingText = '';
        isPlayingNotifier.value = false;
        currentTextNotifier.value = '';
        onCompletion?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isPlaying = false;
        _currentSpeakingText = '';
        isPlayingNotifier.value = false;
        currentTextNotifier.value = '';
      });
    } catch (e) {
      debugPrint('TTS init exception: $e');
    }
  }

  String _getVoiceLanguage(String langCode) {
    switch (langCode) {
      case 'ta': return 'ta-IN';
      case 'hi': return 'hi-IN';
      case 'te': return 'te-IN';
      case 'kn': return 'kn-IN';
      case 'ml': return 'ml-IN';
      default: return 'en-IN';
    }
  }

  /// Expands symbols and removes non-phonetic punctuation so Indic TTS engines
  /// never stall or stop prematurely on symbols like %, °C, ( ), :, etc.
  String _prepareTextForSpeech(String text, String langCode) {
    String cleaned = text
        .replaceAll(RegExp(r'[*#_`>~]'), '')
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'[\(\)]'), ' ')
        .replaceAll(':', ', ')
        .replaceAll(';', ', ');

    if (langCode == 'ta') {
      cleaned = cleaned
          .replaceAll('%', ' சதவீதம் ')
          .replaceAll('°C', ' டிகிரி செல்சியஸ் ')
          .replaceAll('km/h', ' கிலோமீட்டர் மணி ')
          .replaceAll('கி.மீ/மணி', ' கிலோமீட்டர் மணி ')
          .replaceAll('/', ' அல்லது ');
    } else if (langCode == 'hi') {
      cleaned = cleaned
          .replaceAll('%', ' प्रतिशत ')
          .replaceAll('°C', ' डिग्री सेल्सियस ')
          .replaceAll('km/h', ' किलोमीटर प्रति घंटा ')
          .replaceAll('किमी/घंटा', ' किलोमीटर प्रति घंटा ')
          .replaceAll('/', ' या ');
    } else if (langCode == 'te') {
      cleaned = cleaned
          .replaceAll('%', ' శాతం ')
          .replaceAll('°C', ' డిగ్రీ సెల్సియస్ ')
          .replaceAll('కి.మీ/గం', ' కిలోమీటర్లు గంట ')
          .replaceAll('/', ' లేదా ');
    } else if (langCode == 'kn') {
      cleaned = cleaned
          .replaceAll('%', ' ಪ್ರತಿಶತ ')
          .replaceAll('°C', ' ಡಿಗ್ರಿ ಸೆಲ್ಸಿಯಸ್ ')
          .replaceAll('/', ' ಅಥವಾ ');
    } else if (langCode == 'ml') {
      cleaned = cleaned
          .replaceAll('%', ' ശതമാനം ')
          .replaceAll('°C', ' ഡിഗ്രി സെൽഷ്യസ് ')
          .replaceAll('/', ' അല്ലെങ്കിൽ ');
    } else {
      cleaned = cleaned
          .replaceAll('%', ' percent ')
          .replaceAll('°C', ' degrees Celsius ')
          .replaceAll('km/h', ' kilometers per hour ')
          .replaceAll('/', ' or ');
    }

    return cleaned
        .replaceAll(RegExp(r'[\r\n]+'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> speak(String text, {String langCode = 'en', double speed = 0.48}) async {
    if (_isPlaying && _currentSpeakingText == text) {
      await stop();
      return;
    }

    await stop();

    _currentSpeakingText = text;
    _isPlaying = true;
    isPlayingNotifier.value = true;
    currentTextNotifier.value = text;

    try {
      final voiceLang = _getVoiceLanguage(langCode);
      await _flutterTts.setLanguage(voiceLang);
      await _flutterTts.setSpeechRate(speed.clamp(0.2, 1.0));
      await _flutterTts.setPitch(1.0);

      final preparedText = _prepareTextForSpeech(text, langCode);
      await _flutterTts.speak(preparedText);
    } catch (e) {
      debugPrint('TTS speak engine note: $e');
      _isPlaying = false;
      isPlayingNotifier.value = false;
      currentTextNotifier.value = '';
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentSpeakingText = '';
    isPlayingNotifier.value = false;
    currentTextNotifier.value = '';
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
