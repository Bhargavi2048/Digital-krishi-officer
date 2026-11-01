import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/crop_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/advisory_card.dart';
import '../../widgets/crop_card.dart';
import '../../app/routes.dart';
import '../../core/constants/app_constants.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const HomeDashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final weather = Provider.of<WeatherProvider>(context, listen: false);
      weather.detectAndLoadLocationWeather(profile: auth.currentUser);
    });
  }

  String _getTimeGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return context.tr('greetingMorning');
    } else if (hour < 17) {
      return context.tr('greetingAfternoon');
    } else {
      return context.tr('greetingEvening');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final weather = Provider.of<WeatherProvider>(context);
    final cropProv = Provider.of<CropProvider>(context);
    final alertProv = Provider.of<AlertProvider>(context);

    final langProv = Provider.of<LanguageProvider>(context);

    if (weather.currentLanguageCode != langProv.currentLanguageCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        weather.updateLanguage(langProv.currentLanguageCode);
      });
    }

    final farmerName = auth.currentUser?.fullName.isNotEmpty == true
        ? (auth.isGuest ? context.tr('guestFarmer') : auth.currentUser!.fullName)
        : context.tr('farmer');

    final locationText = weather.currentLocationName.isNotEmpty
        ? weather.currentLocationName
        : (auth.currentUser != null
            ? (auth.currentUser!.city.isNotEmpty && auth.currentUser!.city.toLowerCase() != auth.currentUser!.district.toLowerCase()
                ? '${auth.currentUser!.city}, ${auth.currentUser!.district}'
                : '${auth.currentUser!.district}, ${auth.currentUser!.state}')
            : 'Chennai, Tamil Nadu');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.agriculture_rounded, size: 20, color: Color(0xFF2E7D32)),
            ),
          ),
        ),
        leadingWidth: 44,
        titleSpacing: 6,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('appName'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B381F),
              ),
            ),
            Text(
              locationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          // Quick Language Switcher: Tamil, English, Hindi, All
          Consumer<LanguageProvider>(
            builder: (context, langProv, _) {
              final currentCode = langProv.currentLanguageCode;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'Change Language',
                    offset: const Offset(0, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    onSelected: (val) {
                      if (val == 'all') {
                        _showAllLanguagesSheet(context);
                      } else {
                        langProv.setLanguage(val);
                        Provider.of<WeatherProvider>(context, listen: false).updateLanguage(val);
                      }
                    },
                    itemBuilder: (ctx) => [
                      _buildLanguageMenuItem('ta', 'தமிழ்', 'Tamil', currentCode == 'ta'),
                      _buildLanguageMenuItem('en', 'English', 'English', currentCode == 'en'),
                      _buildLanguageMenuItem('hi', 'हिन्दी', 'Hindi', currentCode == 'hi'),
                      const PopupMenuDivider(height: 8),
                      const PopupMenuItem<String>(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(Icons.public, size: 18, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'All Languages...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, size: 14, color: Color(0xFF1B5E20)),
                          const SizedBox(width: 4),
                          Text(
                            _getLangShortLabel(currentCode),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 15, color: Color(0xFF1B5E20)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Alerts Badge Action
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.notifications_outlined, size: 21, color: Color(0xFF1B381F)),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.alerts),
              ),
              if (alertProv.unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Text(
                      '${alertProv.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.bookmark_outline, size: 21, color: Color(0xFF1B381F)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.savedItems),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await weather.loadWeather(profile: auth.currentUser);
          cropProv.loadCrops();
          alertProv.loadAlerts();
        },
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getTimeGreeting(context)}, $farmerName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B381F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 13, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => widget.onNavigateToTab(4), // Profile tab
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.15),
                        child: Text(
                          farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'F',
                          style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Weather Card
              WeatherCard(
                weather: weather.weatherData,
                onTap: () => Navigator.pushNamed(context, AppRoutes.weatherDetail),
              ),
              const SizedBox(height: 16),

              // Today's Agricultural Advisory Card
              AdvisoryCard(
                advisoryText: weather.weatherData?.agriculturalAdvisory ?? '',
                onAskAi: () => widget.onNavigateToTab(1), // AI Officer tab
              ),
              const SizedBox(height: 22),

              // Quick Actions Header
              Text(
                context.tr('quickActions'),
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B381F),
                ),
              ),
              const SizedBox(height: 12),

              // 4 Main Quick Action Buttons Grid
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.smart_toy,
                      label: context.tr('actionAiChat'),
                      color: const Color(0xFF2E7D32),
                      onTap: () => widget.onNavigateToTab(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.camera_alt,
                      label: context.tr('actionDisease'),
                      color: const Color(0xFFC62828),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.diseaseDetection),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.compost,
                      label: context.tr('actionCropRec'),
                      color: const Color(0xFFEF6C00),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.cropRecommendation),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.account_balance,
                      label: context.tr('actionSchemes'),
                      color: const Color(0xFF1565C0),
                      onTap: () => widget.onNavigateToTab(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.storefront_rounded,
                      label: context.tr('actionMandi'),
                      color: const Color(0xFF6A1B9A),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.mandiPrices),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.cloud_sync_rounded,
                      label: context.tr('actionWeatherDetail'),
                      color: const Color(0xFF0277BD),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.weatherDetail),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Crops Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      context.tr('myCropsSummary'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B381F),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateToTab(2), // My Crops tab
                    child: Text(
                      context.tr('viewAll'),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (cropProv.crops.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.grass, color: Colors.grey.shade400, size: 36),
                          const SizedBox(height: 8),
                          Text(context.tr('noCropsYet'), style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.addCrop),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(context.tr('addCrop')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...cropProv.crops.take(2).map(
                      (c) => CropCard(
                        crop: c,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.cropDetail,
                          arguments: c.id,
                        ),
                        onAskAi: () => widget.onNavigateToTab(1),
                      ),
                    ),

              const SizedBox(height: 18),

              // Active Alerts Banner
              if (alertProv.alerts.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.tr('alertsSummary'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B381F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.alerts),
                      child: Text(
                        context.tr('viewAll'),
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.alerts),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: alertProv.alerts.first.severity == 'critical'
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: alertProv.alerts.first.severity == 'critical'
                            ? Colors.red.shade200
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          alertProv.alerts.first.severity == 'critical' ? Icons.error : Icons.notifications_active,
                          color: alertProv.alerts.first.severity == 'critical' ? Colors.red.shade800 : Colors.orange.shade900,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alertProv.alerts.first.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: alertProv.alerts.first.severity == 'critical' ? Colors.red.shade900 : Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alertProv.alerts.first.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getLangShortLabel(String code) {
    switch (code) {
      case 'ta':
        return 'தமிழ்';
      case 'hi':
        return 'हिन्दी';
      case 'te':
        return 'తెలుగు';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      case 'en':
      default:
        return 'English';
    }
  }

  PopupMenuItem<String> _buildLanguageMenuItem(
    String code,
    String nativeName,
    String englishName,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nativeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                  ),
                ),
                Text(
                  englishName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllLanguagesSheet(BuildContext context) {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Text(
                        ctx.tr('selectLanguage'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B381F),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: AppConstants.supportedLanguages.length,
                    itemBuilder: (c, idx) {
                      final item = AppConstants.supportedLanguages[idx];
                      final code = item['code'] ?? 'en';
                      final isSelected = langProv.currentLanguageCode == code;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          child: Text(
                            item['flag'] ?? '🇮🇳',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        title: Text(
                          item['native'] ?? '',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                          ),
                        ),
                        subtitle: Text(item['name'] ?? ''),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
                            : null,
                        onTap: () {
                          langProv.setLanguage(code);
                          Provider.of<WeatherProvider>(context, listen: false).updateLanguage(code);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}