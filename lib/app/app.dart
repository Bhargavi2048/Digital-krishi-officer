import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/disease_provider.dart';
import '../providers/crop_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/scheme_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/saved_provider.dart';
import '../providers/mandi_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/responsive_mobile_shell.dart';
import 'theme.dart';
import 'routes.dart';

class DigitalKrishiOfficerApp extends StatelessWidget {
  const DigitalKrishiOfficerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => DiseaseProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => SchemeProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => SavedProvider()),
        ChangeNotifierProvider(create: (_) => MandiProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProv, langProv, _) {
          return MaterialApp(
            title: 'Digital Krishi Officer',
            debugShowCheckedModeBanner: false,
            theme: themeProv.isOutdoorMode ? AppTheme.outdoorTheme : AppTheme.lightTheme,
            darkTheme: themeProv.isOutdoorMode ? AppTheme.outdoorTheme : AppTheme.darkTheme,
            themeMode: themeProv.themeMode,
            locale: langProv.currentLocale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ta', ''),
              Locale('hi', ''),
              Locale('te', ''),
              Locale('kn', ''),
              Locale('ml', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            builder: (context, child) {
              return ResponsiveMobileShell(child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
}
