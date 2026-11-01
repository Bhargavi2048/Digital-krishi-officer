import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/storage/local_storage_service.dart';
import '../core/services/gemini_service.dart';
import '../core/services/tts_service.dart';
import '../core/utils/image_helper.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/farmer_profile.dart';
import '../models/saved_item.dart';

class ChatProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final GeminiService _gemini = GeminiService();
  final TtsService _tts = TtsService();

  String _currentConversationId = 'conv_default';
  List<ChatMessage> _messages = [];
  List<Conversation> _conversations = [];
  bool _isThinking = false;
  String? _thinkingStatus;
  String? _errorMessage;

  String get currentConversationId => _currentConversationId;
  List<ChatMessage> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  bool get isThinking => _isThinking;
  String? get thinkingStatus => _thinkingStatus;
  String? get errorMessage => _errorMessage;

  ChatProvider() {
    initChat();
  }

  Future<void> initChat() async {
    _conversations = _storage.getConversations();
    if (_conversations.isEmpty) {
      final defaultConv = Conversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Agricultural Advisory Consultation',
      );
      _conversations = [defaultConv];
      await _storage.saveConversations(_conversations);
    }
    _currentConversationId = _conversations.first.id;
    _loadMessagesForCurrentConversation();
  }

  void _loadMessagesForCurrentConversation() {
    _messages = _storage.getMessages(_currentConversationId);
    if (_messages.isEmpty) {
      _messages = [
        ChatMessage(
          id: 'welcome_msg',
          conversationId: _currentConversationId,
          text: 'Vanakkam & Namaste Farmer! I am your Digital Krishi Officer. How can I help you today? You can ask about crop care, fertilizer dosage, pest remedies, or upload leaf photos for disease check.',
          isUser: false,
        )
      ];
      _storage.saveMessages(_currentConversationId, _messages);
    }
    notifyListeners();
  }

  void selectConversation(String conversationId) {
    _currentConversationId = conversationId;
    _loadMessagesForCurrentConversation();
  }

  Future<void> startNewConversation() async {
    final newConv = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Agricultural Advisory ${DateTime.now().day}/${DateTime.now().month}',
    );
    _conversations.insert(0, newConv);
    await _storage.saveConversations(_conversations);
    _currentConversationId = newConv.id;
    _messages = [
      ChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversationId,
        text: 'Hello! I am ready to advise you on your crops. How can I assist you right now?',
        isUser: false,
      )
    ];
    await _storage.saveMessages(_currentConversationId, _messages);
    notifyListeners();
  }

  // --- SEND MESSAGE (TEXT / IMAGE / VIDEO) ---
  Future<String?> sendMessage({
    required String text,
    FarmerProfile? profile,
    String langCode = 'en',
    String? imagePath,
    Uint8List? imageBytes,
    String? videoPath,
    Uint8List? videoBytes,
    bool isVideoFrame = false,
    String? mediaName,
    int? mediaSizeBytes,
    String? mimeType,
    bool isVoiceMessage = false,
  }) async {
    final effectiveBytes = imageBytes ?? videoBytes;
    final isVideo = isVideoFrame || (videoBytes != null) || (videoPath != null);

    if (text.trim().isEmpty && imagePath == null && effectiveBytes == null && videoPath == null) return null;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _currentConversationId,
      text: text.trim().isEmpty ? (isVideo ? 'Analyzed Video Record' : 'Analyzed Crop Image') : text.trim(),
      isUser: true,
      imagePath: imagePath,
      imageBytes: isVideo ? null : imageBytes,
      videoPath: videoPath,
      isVideoFrameAnalysis: isVideo,
      mediaName: mediaName,
      mediaSizeBytes: mediaSizeBytes,
      isVoiceMessage: isVoiceMessage,
    );

    _messages.add(userMsg);
    _isThinking = true;
    _thinkingStatus = 'Krishi Officer is thinking...';
    _errorMessage = null;
    notifyListeners();

    await _storage.saveMessages(_currentConversationId, _messages);

    String? generatedResponse;

    try {
      final detectedMime = mimeType ??
          (isVideo
              ? (mediaName?.toLowerCase().endsWith('.mov') == true ? 'video/quicktime' : 'video/mp4')
              : ImageHelper.detectMimeType(mediaName ?? imagePath, effectiveBytes));

      final aiResponseText = await _gemini.askKrishiOfficer(
        prompt: userMsg.text,
        profile: profile,
        langCode: langCode,
        imagePath: imagePath ?? videoPath,
        imageBytes: effectiveBytes,
        mimeType: detectedMime,
        isVideo: isVideo,
        onStatusUpdate: (status) {
          _thinkingStatus = status;
          notifyListeners();
        },
      );

      generatedResponse = aiResponseText;

      final aiMsg = ChatMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversationId,
        text: aiResponseText,
        isUser: false,
      );

      _messages.add(aiMsg);
      await _storage.saveMessages(_currentConversationId, _messages);

      // Update conversation title & last message preview
      final convIndex = _conversations.indexWhere((c) => c.id == _currentConversationId);
      if (convIndex >= 0) {
        final existing = _conversations[convIndex];
        final newTitle = existing.title.contains('Consultation')
            ? (userMsg.text.length > 28 ? '${userMsg.text.substring(0, 25)}...' : userMsg.text)
            : existing.title;
        _conversations[convIndex] = existing.copyWith(
          title: newTitle,
          lastMessage: aiResponseText.length > 40 ? '${aiResponseText.substring(0, 37)}...' : aiResponseText,
          updatedAt: DateTime.now(),
        );
        await _storage.saveConversations(_conversations);
      }
    } catch (e) {
      _errorMessage = 'Could not get response: $e';
    } finally {
      _isThinking = false;
      _thinkingStatus = null;
      notifyListeners();
    }
    return generatedResponse;
  }

  // --- RETRY LAST USER MESSAGE ---
  Future<void> retryLastMessage(FarmerProfile? profile, String langCode) async {
    if (_messages.isEmpty) return;
    final lastUserMsg = _messages.lastWhere((m) => m.isUser, orElse: () => _messages.first);
    if (lastUserMsg.isUser) {
      await sendMessage(
        text: lastUserMsg.text,
        profile: profile,
        langCode: langCode,
        imagePath: lastUserMsg.imagePath,
        imageBytes: lastUserMsg.imageBytes,
        videoPath: lastUserMsg.videoPath,
        isVideoFrame: lastUserMsg.isVideoFrameAnalysis,
        mediaName: lastUserMsg.mediaName,
        mediaSizeBytes: lastUserMsg.mediaSizeBytes,
      );
    }
  }

  // --- TEXT TO SPEECH ---
  void speakMessage(String text, String langCode) {
    _tts.speak(text, langCode: langCode);
  }

  // --- BOOKMARK AI RESPONSE ---
  Future<bool> saveAdviceToBookmarks(String adviceText, String topic) async {
    try {
      final item = SavedItem(
        id: 'saved_ai_${DateTime.now().millisecondsSinceEpoch}',
        title: topic.isNotEmpty ? topic : 'AI Krishi Officer Advice',
        subtitle: adviceText.length > 60 ? '${adviceText.substring(0, 57)}...' : adviceText,
        category: 'ai_advice',
        content: adviceText,
      );
      await _storage.saveItem(item);
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- CLEAR CONVERSATION ---
  Future<void> clearCurrentChat() async {
    _messages.clear();
    await _storage.saveMessages(_currentConversationId, _messages);
    notifyListeners();
  }

  // --- DELETE CONVERSATION ---
  Future<void> deleteConversation(String id) async {
    await _storage.deleteConversation(id);
    _conversations = _storage.getConversations();
    if (_conversations.isEmpty) {
      await startNewConversation();
    } else {
      _currentConversationId = _conversations.first.id;
      _loadMessagesForCurrentConversation();
    }
    notifyListeners();
  }
}
