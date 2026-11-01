import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/chat_message.dart';
import '../../../core/utils/image_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_image_preview.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;
  final VoidCallback onSave;
  final VoidCallback? onRetry;
  final bool isSpeaking;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
    required this.onSave,
    this.onRetry,
    this.isSpeaking = false,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('🌾', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: isUser ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Voice Message Header Badge
                      if (message.isVoiceMessage) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.white.withValues(alpha: 0.2) : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, size: 16, color: isUser ? Colors.white : const Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Text(
                                'Voice Query',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUser ? Colors.white : const Color(0xFF2E7D32),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.graphic_eq, size: 16, color: isUser ? Colors.white70 : const Color(0xFF2E7D32)),
                            ],
                          ),
                        ),
                      ],

                      // Attached Image Preview if any (only for non-video messages)
                      if (!message.isVideoFrameAnalysis &&
                          (message.imageBytes != null || (message.imagePath != null && message.imagePath!.isNotEmpty))) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppImagePreview(
                            bytes: message.imageBytes,
                            path: message.imagePath,
                            width: 220,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Attached Video Preview if any
                      if (message.isVideoFrameAnalysis ||
                          message.videoPath != null ||
                          (message.mediaName != null && ImageHelper.isVideoFileName(message.mediaName))) ...[
                        Container(
                          width: 220,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isUser ? Colors.white24 : Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.videocam_rounded, size: 22, color: isUser ? Colors.white : Colors.greenAccent),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.mediaName ?? 'Attached Video',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (message.mediaSizeBytes != null)
                                      Text(
                                        ImageHelper.formatBytes(message.mediaSizeBytes!),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isUser ? Colors.white70 : Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Message Body
                      if (isUser)
                        Text(
                          message.text,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        )
                      else
                        MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14, color: Color(0xFF263238), height: 1.45),
                            h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            listBullet: const TextStyle(fontSize: 14, color: Color(0xFF2E7D32)),
                            strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser ? Colors.white70 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  child: const Icon(Icons.person, size: 18, color: Color(0xFF1B5E20)),
                ),
              ],
            ],
          ),

          // Action Toolbar for AI responses
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Row(
                children: [
                  if (onSpeak != null)
                    IconButton(
                      icon: Icon(
                        isSpeaking ? Icons.volume_off : Icons.volume_up,
                        size: 18,
                        color: isSpeaking ? Colors.red : Colors.grey.shade600,
                      ),
                      tooltip: 'Speak Text',
                      onPressed: onSpeak,
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('copySuccess')), duration: const Duration(seconds: 2)),
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_outline, size: 18, color: Colors.grey),
                    tooltip: 'Save',
                    onPressed: onSave,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                    tooltip: 'Share',
                    onPressed: () {
                      Share.share(
                        '${message.text}\n\n— Advice from Digital Krishi Officer (AI Agricultural Assistant)',
                        subject: 'Agricultural Guidance',
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  if (onRetry != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                      tooltip: 'Retry',
                      onPressed: onRetry,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
