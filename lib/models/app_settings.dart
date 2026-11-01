import 'dart:convert';

class AppSettings {
  final String languageCode;
  final bool isDarkMode;
  final String themeMode; // 'light', 'dark', 'outdoor'
  final double voiceSpeed;
  final bool notificationsEnabled;
  final bool offlineCacheEnabled;

  AppSettings({
    this.languageCode = 'en',
    this.isDarkMode = false,
    String? themeMode,
    this.voiceSpeed = 1.0,
    this.notificationsEnabled = true,
    this.offlineCacheEnabled = true,
  }) : themeMode = themeMode ?? (isDarkMode ? 'dark' : 'light');

  Map<String, dynamic> toMap() {
    return {
      'languageCode': languageCode,
      'isDarkMode': isDarkMode,
      'themeMode': themeMode,
      'voiceSpeed': voiceSpeed,
      'notificationsEnabled': notificationsEnabled,
      'offlineCacheEnabled': offlineCacheEnabled,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final bool isDark = map['isDarkMode'] ?? false;
    final String mode = map['themeMode'] ?? (isDark ? 'dark' : 'light');
    return AppSettings(
      languageCode: map['languageCode'] ?? 'en',
      isDarkMode: isDark || mode == 'dark' || mode == 'outdoor',
      themeMode: mode,
      voiceSpeed: (map['voiceSpeed'] is num) ? (map['voiceSpeed'] as num).toDouble() : 1.0,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      offlineCacheEnabled: map['offlineCacheEnabled'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) => AppSettings.fromMap(json.decode(source));

  AppSettings copyWith({
    String? languageCode,
    bool? isDarkMode,
    String? themeMode,
    double? voiceSpeed,
    bool? notificationsEnabled,
    bool? offlineCacheEnabled,
  }) {
    final effectiveTheme = themeMode ?? (isDarkMode != null ? (isDarkMode ? 'dark' : 'light') : this.themeMode);
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? (effectiveTheme == 'dark' || effectiveTheme == 'outdoor'),
      themeMode: effectiveTheme,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      offlineCacheEnabled: offlineCacheEnabled ?? this.offlineCacheEnabled,
    );
  }
}
