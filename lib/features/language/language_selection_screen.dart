import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../providers/weather_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../app/routes.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final bool isFromSettings;

  const LanguageSelectionScreen({super.key, this.isFromSettings = false});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text(context.tr('languageSetting')),
        automaticallyImplyLeading: isFromSettings,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B381F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your preferred language for advice, weather, and AI conversation.',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: AppConstants.supportedLanguages.length,
                  itemBuilder: (context, idx) {
                    final lang = AppConstants.supportedLanguages[idx];
                    final code = lang['code']!;
                    final isSelected = langProvider.currentLanguageCode == code;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ListTile(
                        onTap: () async {
                          await langProvider.setLanguage(code);
                          if (context.mounted) {
                            try {
                              Provider.of<WeatherProvider>(context, listen: false).updateLanguage(code);
                            } catch (_) {}
                          }
                          if (!isFromSettings) {
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, AppRoutes.register);
                          } else {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2E7D32).withOpacity(0.12)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              lang['flag']!,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        title: Text(
                          lang['native']!,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF263238),
                          ),
                        ),
                        subtitle: Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24)
                            : Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 22),
                      ),
                    );
                  },
                ),
              ),
              if (!isFromSettings) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.register);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      context.tr('confirm'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
