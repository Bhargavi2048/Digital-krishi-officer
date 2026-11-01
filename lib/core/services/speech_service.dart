import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  Function(String status)? onStatusListener;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          _isListening = false;
          onStatusListener?.call('error');
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
          onStatusListener?.call(val);
        },
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  String _getLocaleIdForLanguage(String langCode) {
    switch (langCode) {
      case 'ta': return 'ta_IN';
      case 'hi': return 'hi_IN';
      case 'te': return 'te_IN';
      case 'kn': return 'kn_IN';
      case 'ml': return 'ml_IN';
      default: return 'en_IN';
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required String langCode,
    Duration? pauseFor,
    Duration? listenFor,
  }) async {
    final available = await init();
    if (!available) {
      debugPrint('Speech recognition not available on this device');
      return;
    }

    _isListening = true;
    final locale = _getLocaleIdForLanguage(langCode);

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: locale,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        listenFor: listenFor ?? const Duration(seconds: 30),
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }
}
