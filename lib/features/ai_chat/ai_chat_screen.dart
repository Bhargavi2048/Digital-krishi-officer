import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_image_preview.dart';
import '../../core/utils/image_helper.dart';
import '../../core/utils/camera_helper.dart';
import 'widgets/chat_bubble.dart';
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
}
