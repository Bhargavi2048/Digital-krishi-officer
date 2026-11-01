import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/tts_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_image_preview.dart';
import '../../core/utils/image_helper.dart';
import '../../core/utils/camera_helper.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/voice_input_sheet.dart';
import 'chat_history_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Attached media state for image and video
  Uint8List? _attachedMediaBytes;
  String? _attachedMediaPath;
  String? _attachedMediaName;
  int? _attachedMediaSize;
  bool _isAttachedVideo = false;

  // Selected chat communication language
  String? _selectedChatLanguage;

  // Hands-free continuous conversational voice state
  bool _isHandsFreeMode = false;
  String _handsFreeStatus = 'idle'; // 'listening', 'thinking', 'speaking', 'idle'
  String _lastHeardSpeech = '';
  Timer? _silenceTimer;
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();

  static const Map<String, String> _languages = {
    'en': 'English',
    'ta': 'தமிழ் (Tamil)',
    'hi': 'हिन्दी (Hindi)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
  };

  static const Map<String, String> _shortLangNames = {
    'en': 'English',
    'ta': 'தமிழ்',
    'hi': 'हिन्दी',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
  };

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.stopListening();
    _tts.stop();
    _tts.onCompletion = null;
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleHandsFreeMode() {
    if (_isHandsFreeMode) {
      _stopHandsFreeMode();
    } else {
      _startHandsFreeMode();
    }
  }

  void _startHandsFreeMode() {
    setState(() {
      _isHandsFreeMode = true;
      _handsFreeStatus = 'listening';
      _lastHeardSpeech = '';
    });
    _startListeningLoop();
  }

  void _stopHandsFreeMode() {
    _silenceTimer?.cancel();
    _speech.stopListening();
    _tts.stop();
    _tts.onCompletion = null;
    setState(() {
      _isHandsFreeMode = false;
      _handsFreeStatus = 'idle';
      _lastHeardSpeech = '';
    });
  }

  Future<void> _startListeningLoop() async {
    if (!_isHandsFreeMode || !mounted) return;

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final activeLang = _selectedChatLanguage ?? lang.currentLanguageCode;

    setState(() {
      _handsFreeStatus = 'listening';
      _lastHeardSpeech = '';
    });

    _speech.onStatusListener = (status) {
      if (!_isHandsFreeMode || !mounted) return;
      if ((status == 'done' || status == 'notListening') && _handsFreeStatus == 'listening') {
        if (_lastHeardSpeech.trim().isNotEmpty) {
          _submitHandsFreeQuery(_lastHeardSpeech.trim());
        }
      }
    };

    await _speech.startListening(
      langCode: activeLang,
      pauseFor: const Duration(seconds: 2),
      listenFor: const Duration(seconds: 35),
      onResult: (spokenText) {
        if (!_isHandsFreeMode || !mounted) return;
        setState(() {
          _lastHeardSpeech = spokenText;
        });

        _silenceTimer?.cancel();
        _silenceTimer = Timer(const Duration(milliseconds: 1400), () {
          if (_isHandsFreeMode && mounted && _lastHeardSpeech.trim().isNotEmpty && _handsFreeStatus == 'listening') {
            _submitHandsFreeQuery(_lastHeardSpeech.trim());
          }
        });
      },
    );
  }

  Future<void> _submitHandsFreeQuery(String queryText) async {
    if (!_isHandsFreeMode || queryText.isEmpty || !mounted) return;

    _silenceTimer?.cancel();
    await _speech.stopListening();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final activeLang = _selectedChatLanguage ?? lang.currentLanguageCode;

    setState(() {
      _handsFreeStatus = 'thinking';
    });

    final aiResponse = await chat.sendMessage(
      text: queryText,
      profile: auth.currentUser,
      langCode: activeLang,
      isVoiceMessage: true,
    );

    _scrollToBottom();

    if (!_isHandsFreeMode || !mounted) return;

    if (aiResponse != null && aiResponse.trim().isNotEmpty) {
      setState(() {
        _handsFreeStatus = 'speaking';
      });

      _tts.onCompletion = () {
        if (!_isHandsFreeMode || !mounted) return;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_isHandsFreeMode && mounted) {
            _startListeningLoop();
          }
        });
      };

      await _tts.speak(aiResponse, langCode: activeLang);
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isHandsFreeMode && mounted) {
          _startListeningLoop();
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final captured = await CameraHelper.captureLivePhoto(context);
        if (captured != null) {
          setState(() {
            _attachedMediaBytes = captured.bytes;
            _attachedMediaPath = captured.path;
            _attachedMediaName = captured.name;
            _attachedMediaSize = captured.size;
            _isAttachedVideo = false;
          });
          return;
        }
      }

      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final size = await picked.length();
        setState(() {
          _attachedMediaBytes = bytes;
          _attachedMediaPath = picked.path;
          _attachedMediaName = picked.name;
          _attachedMediaSize = size;
          _isAttachedVideo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (picked != null) {
        final size = await picked.length();
        if (size > 15 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video exceeds 15MB limit. Please choose a shorter clip for AI analysis.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final bytes = await picked.readAsBytes();
        setState(() {
          _attachedMediaBytes = bytes;
          _attachedMediaPath = picked.path;
          _attachedMediaName = picked.name;
          _attachedMediaSize = size;
          _isAttachedVideo = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select video: $e')),
        );
      }
    }
  }

  void _clearAttachedMedia() {
    setState(() {
      _attachedMediaBytes = null;
      _attachedMediaPath = null;
      _attachedMediaName = null;
      _attachedMediaSize = null;
      _isAttachedVideo = false;
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    final hasMedia = _attachedMediaBytes != null || _attachedMediaPath != null;

    if (text.isEmpty && !hasMedia) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    final mediaBytes = _attachedMediaBytes;
    final mediaPath = _attachedMediaPath;
    final mediaName = _attachedMediaName;
    final mediaSize = _attachedMediaSize;
    final isVideo = _isAttachedVideo;

    // Clear state before sending for instant UI responsiveness
    _textController.clear();
    _clearAttachedMedia();

    String messageText = text;
    if (messageText.isEmpty && hasMedia) {
      messageText = isVideo
          ? 'Please examine this crop video recording. What disease, pest, or deficiency is visible, and what remedies are recommended?'
          : 'Please examine this crop leaf/plant photo. What disease or pest is affecting this crop, and how can I treat it?';
    }

    final activeLang = _selectedChatLanguage ?? lang.currentLanguageCode;

    await chat.sendMessage(
      text: messageText,
      profile: auth.currentUser,
      langCode: activeLang,
      imagePath: isVideo ? null : mediaPath,
      imageBytes: isVideo ? null : mediaBytes,
      videoPath: isVideo ? mediaPath : null,
      videoBytes: isVideo ? mediaBytes : null,
      isVideoFrame: isVideo,
      mediaName: mediaName,
      mediaSizeBytes: mediaSize,
    );

    _scrollToBottom();
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Crop Media',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                ),
                title: Text(context.tr('takePhoto')),
                subtitle: const Text('Capture live leaf or plant symptom photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                ),
                title: Text(context.tr('uploadImage')),
                subtitle: const Text('Choose crop photo from phone gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.videocam, color: Color(0xFF2E7D32)),
                ),
                title: Text(context.tr('uploadVideo')),
                subtitle: const Text('Short video clip of affected plant area (up to 30s)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('aiKrishiOfficer'),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      'AI replies in: ${_languages[_selectedChatLanguage ?? lang.currentLanguageCode] ?? 'English'}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Hands-free continuous voice conversation toggle
          IconButton(
            tooltip: _isHandsFreeMode ? context.tr('handsFreeStop') : context.tr('startHandsFree'),
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isHandsFreeMode ? Colors.red.shade600 : const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isHandsFreeMode
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isHandsFreeMode ? Icons.mic_rounded : Icons.record_voice_over_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isHandsFreeMode ? 'LIVE' : 'VOICE',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            onPressed: _toggleHandsFreeMode,
          ),

          // Compact AI language selector button
          PopupMenuButton<String>(
            tooltip: 'Select AI Language',
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E7D32), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate, size: 13, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 3),
                  Text(
                    _shortLangNames[_selectedChatLanguage ?? lang.currentLanguageCode] ?? 'EN',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF2E7D32)),
                ],
              ),
            ),
            onSelected: (val) {
              setState(() {
                _selectedChatLanguage = val;
              });
              // Scoped strictly to chatbot only - do NOT alter global application locale
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('AI responses set strictly to ${_languages[val] ?? val}'),
                  backgroundColor: const Color(0xFF2E7D32),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (ctx) => _languages.entries.map((entry) {
              final isSelected = (_selectedChatLanguage ?? lang.currentLanguageCode) == entry.key;
              return PopupMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'new') {
                chat.startNewConversation();
              } else if (val == 'clear') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.tr('clearChat')),
                    content: Text(context.tr('clearChatConfirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
                      ElevatedButton(
                        onPressed: () {
                          chat.clearCurrentChat();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(context.tr('confirm')),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'new', child: Text('New Conversation')),
              PopupMenuItem(value: 'clear', child: Text(context.tr('clearChat'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Continuous Hands-Free Conversational Voice Banner
          if (_isHandsFreeMode)
            _buildHandsFreeActiveBanner(context, _selectedChatLanguage ?? lang.currentLanguageCode),
          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chat.messages.length,
              itemBuilder: (context, idx) {
                final msg = chat.messages[idx];
                return ChatBubble(
                  message: msg,
                  onSpeak: () => chat.speakMessage(msg.text, lang.currentLanguageCode),
                  onSave: () async {
                    final saved = await chat.saveAdviceToBookmarks(msg.text, 'Agricultural Advice');
                    if (context.mounted && saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('saveSuccess')), duration: const Duration(seconds: 2)),
                      );
                    }
                  },
                  onRetry: idx == chat.messages.length - 1 && !msg.isUser
                      ? () => chat.retryLastMessage(auth.currentUser, lang.currentLanguageCode)
                      : null,
                );
              },
            ),
          ),

          // Thinking / Loading Indicator
          if (chat.isThinking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const SpinKitThreeBounce(color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chat.thinkingStatus ?? context.tr('aiThinking'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Attached Media Preview Bar
          if (_attachedMediaBytes != null || _attachedMediaPath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                border: Border(
                  top: BorderSide(color: Colors.green.shade200, width: 1),
                  bottom: BorderSide(color: Colors.green.shade100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isAttachedVideo
                        ? Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFF1E293B),
                            child: const Icon(Icons.videocam_rounded, color: Colors.greenAccent, size: 24),
                          )
                        : AppImagePreview(
                            bytes: _attachedMediaBytes,
                            path: _attachedMediaPath,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isAttachedVideo ? 'Crop Video Attached' : 'Crop Photo Attached',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          _attachedMediaSize != null
                              ? '${_attachedMediaName ?? (_isAttachedVideo ? 'Video clip' : 'Image')} • ${ImageHelper.formatBytes(_attachedMediaSize!)}'
                              : (_attachedMediaName ?? (_isAttachedVideo ? 'Video clip selected' : 'Image selected')),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF2E7D32)),
                    tooltip: 'Remove attachment',
                    onPressed: _clearAttachedMedia,
                  ),
                ],
              ),
            ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment button (Image/Camera/Video)
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate, color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Attach photo or video',
                    onPressed: _showMediaPickerOptions,
                  ),

                  // Voice recording button: Tap starts hands-free, long-press opens voice sheet
                  IconButton(
                    icon: Icon(
                      _isHandsFreeMode ? Icons.mic : Icons.mic_none_rounded,
                      color: _isHandsFreeMode ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: _isHandsFreeMode ? context.tr('handsFreeStop') : context.tr('startHandsFree'),
                    onPressed: _toggleHandsFreeMode,
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E2B20)
                            : const Color(0xFFF1F4F1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendMessage(),
                        decoration: InputDecoration(
                          hintText: (_attachedMediaBytes != null || _attachedMediaPath != null)
                              ? 'Ask about this media, or tap send...'
                              : context.tr('chatHint'),
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                      onPressed: _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandsFreeActiveBanner(BuildContext context, String currentLangCode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bannerBg;
    IconData statusIcon;
    String statusTitle;
    Color statusColor;

    switch (_handsFreeStatus) {
      case 'listening':
        bannerBg = isDark ? const Color(0xFF1B281D) : const Color(0xFFE8F5E9);
        statusIcon = Icons.mic_rounded;
        statusTitle = context.tr('handsFreeListening');
        statusColor = const Color(0xFF2E7D32);
        break;
      case 'thinking':
        bannerBg = isDark ? const Color(0xFF262010) : const Color(0xFFFFF8E1);
        statusIcon = Icons.psychology_rounded;
        statusTitle = context.tr('handsFreeThinking');
        statusColor = const Color(0xFFF57F17);
        break;
      case 'speaking':
        bannerBg = isDark ? const Color(0xFF102027) : const Color(0xFFE1F5FE);
        statusIcon = Icons.volume_up_rounded;
        statusTitle = context.tr('handsFreeSpeaking');
        statusColor = const Color(0xFF0288D1);
        break;
      default:
        bannerBg = isDark ? const Color(0xFF1B281D) : const Color(0xFFE8F5E9);
        statusIcon = Icons.record_voice_over_rounded;
        statusTitle = context.tr('handsFreeActive');
        statusColor = const Color(0xFF2E7D32);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.4),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _languages[currentLangCode]?.split(' ').first ?? currentLangCode.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                if (_lastHeardSpeech.isNotEmpty && _handsFreeStatus == 'listening')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '🗣️ $_lastHeardSpeech',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _stopHandsFreeMode,
            icon: const Icon(Icons.stop_circle_rounded, size: 14),
            label: Text(context.tr('handsFreeStop')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
