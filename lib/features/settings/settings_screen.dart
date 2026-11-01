import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../language/language_selection_screen.dart';
import 'privacy_screen.dart';
import 'about_screen.dart';
import 'expert_escalation_screen.dart';
import '../../app/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final langProv = Provider.of<LanguageProvider>(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text(context.tr('settingsTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Language & Theme Preferences
          _buildSettingsCard(
            context: context,
            title: 'Preferences',
            children: [
              ListTile(
                leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                title: Text(context.tr('languageSetting')),
                subtitle: Text(langProv.currentLanguageCode.toUpperCase()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(isFromSettings: true),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          context.tr('themeSetting'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildThemeOption(
                          context: context,
                          title: context.tr('themeLight'),
                          icon: Icons.wb_sunny_rounded,
                          isSelected: themeProv.themeType == AppThemeModeType.light,
                          onTap: () => themeProv.setThemeType(AppThemeModeType.light),
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context: context,
                          title: context.tr('themeDark'),
                          icon: Icons.nightlight_round,
                          isSelected: themeProv.themeType == AppThemeModeType.dark,
                          onTap: () => themeProv.setThemeType(AppThemeModeType.dark),
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context: context,
                          title: context.tr('themeOutdoor'),
                          icon: Icons.wb_sunny,
                          isSelected: themeProv.themeType == AppThemeModeType.outdoor,
                          badge: 'FIELD',
                          onTap: () => themeProv.setThemeType(AppThemeModeType.outdoor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Escalation & Support Directory
          _buildSettingsCard(
            context: context,
            title: 'Support & Escalation',
            children: [
              ListTile(
                leading: Icon(Icons.support_agent, color: Theme.of(context).colorScheme.primary),
                title: Text(context.tr('expertHelpline')),
                subtitle: const Text('Kisan Call Center (1800-180-1551) & Extension Officers'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpertEscalationScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legal & About
          _buildSettingsCard(
            context: context,
            title: 'Information & Safety',
            children: [
              ListTile(
                leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                title: Text(context.tr('privacyPolicy')),
                subtitle: const Text('Local data policy and camera/mic permissions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                title: Text(context.tr('aboutApp')),
                subtitle: const Text('Version 1.0.0 • AI disclaimer & credits'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logout Card
          _buildSettingsCard(
            context: context,
            title: 'Session',
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  context.tr('logout'),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await authProv.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 22, color: isSelected ? primary : Colors.grey.shade600),
                  if (badge != null)
                    Positioned(
                      top: -8,
                      right: -16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required BuildContext context, required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? theme.colorScheme.primary : const Color(0xFF78909C),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? (theme.cardTheme.color ?? const Color(0xFF1B281D)) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? theme.colorScheme.primary.withOpacity(0.4) : Colors.grey.shade200,
              width: isDark ? 1.5 : 1.0,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
