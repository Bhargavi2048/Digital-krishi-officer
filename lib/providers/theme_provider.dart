import 'package:flutter/material.dart';
import '../core/storage/local_storage_service.dart';

enum AppThemeModeType {
  light,
  dark,
  outdoor,
}

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  AppThemeModeType _themeType = AppThemeModeType.light;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isOutdoorMode => _themeType == AppThemeModeType.outdoor;
  AppThemeModeType get themeType => _themeType;

  String get themeModeString {
    switch (_themeType) {
      case AppThemeModeType.outdoor:
        return 'outdoor';
      case AppThemeModeType.dark:
        return 'dark';
      case AppThemeModeType.light:
        return 'light';
    }
  }

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    final settings = _storage.getSettings();
    if (settings.themeMode == 'outdoor') {
      _themeType = AppThemeModeType.outdoor;
      _isDarkMode = true;
    } else if (settings.themeMode == 'dark' || settings.isDarkMode) {
      _themeType = AppThemeModeType.dark;
      _isDarkMode = true;
    } else {
      _themeType = AppThemeModeType.light;
      _isDarkMode = false;
    }
    notifyListeners();
  }

  Future<void> setThemeType(AppThemeModeType type) async {
    _themeType = type;
    _isDarkMode = type == AppThemeModeType.dark || type == AppThemeModeType.outdoor;
    final currentSettings = _storage.getSettings();
    await _storage.saveSettings(currentSettings.copyWith(
      themeMode: themeModeString,
      isDarkMode: _isDarkMode,
    ));
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeType(isDark ? AppThemeModeType.dark : AppThemeModeType.light);
  }
}
