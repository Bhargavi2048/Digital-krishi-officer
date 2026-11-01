import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../core/services/tts_service.dart';
import '../providers/language_provider.dart';

class AdvisoryCard extends StatelessWidget {
  final String advisoryText;
  final VoidCallback? onAskAi;

  const AdvisoryCard({
    super.key,
    required this.advisoryText,
    this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fallback = context.tr('defaultAdvisory');
    final effectiveText = advisoryText.trim().isNotEmpty ? advisoryText : fallback;

    return Card(
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5)
            : BorderSide(color: const Color(0xFF2E7D32).withOpacity(0.2)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? (theme.cardTheme.color ?? const Color(0xFF1B281D)) : const Color(0xFFF1F8E9),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('todayAdvisory'),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? theme.colorScheme.primary : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              effectiveText,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? Colors.white : const Color(0xFF2E3D30),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: TtsService().isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      final currentText = TtsService().currentTextNotifier.value;
                      final isThisSpeaking = isPlaying && currentText == effectiveText;
                      return TextButton.icon(
                        onPressed: () {
                          if (isThisSpeaking) {
                            TtsService().stop();
                          } else {
                            final langProv = Provider.of<LanguageProvider>(context, listen: false);
                            TtsService().speak(effectiveText, langCode: langProv.currentLanguageCode);
                          }
                        },
                        icon: Icon(
                          isThisSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          size: 16,
                          color: isThisSpeaking ? Colors.red.shade400 : theme.colorScheme.primary,
                        ),
                        label: Text(
                          isThisSpeaking ? context.tr('stopVoice') : context.tr('listenAdvisory'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isThisSpeaking ? Colors.red.shade400 : theme.colorScheme.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: isThisSpeaking
                              ? Colors.red.withOpacity(0.15)
                              : theme.colorScheme.primary.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  ),
                ),
                if (onAskAi != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: TextButton.icon(
                      onPressed: onAskAi,
                      icon: Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                      label: Text(
                        context.tr('askAi'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
