import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.audioEnabled,
    required this.effectsEnabled,
    required this.backgroundAudioEnabled,
    required this.masterVolume,
    required this.effectsVolume,
    required this.backgroundVolume,
    required this.hapticsEnabled,
    required this.compactHorseCards,
    required this.breedingTimerAlerts,
    required this.birthReadyAlerts,
    required this.pregnancyDueSoonAlerts,
    required this.healingCompleteAlerts,
    required this.recoveryCompleteAlerts,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      audioEnabled: true,
      effectsEnabled: true,
      backgroundAudioEnabled: true,
      masterVolume: 0.78,
      effectsVolume: 0.82,
      backgroundVolume: 0.9,
      hapticsEnabled: true,
      compactHorseCards: false,
      breedingTimerAlerts: true,
      birthReadyAlerts: true,
      pregnancyDueSoonAlerts: true,
      healingCompleteAlerts: true,
      recoveryCompleteAlerts: true,
    );
  }

  final bool audioEnabled;
  final bool effectsEnabled;
  final bool backgroundAudioEnabled;
  final double masterVolume;
  final double effectsVolume;
  final double backgroundVolume;
  final bool hapticsEnabled;
  final bool compactHorseCards;
  final bool breedingTimerAlerts;
  final bool birthReadyAlerts;
  final bool pregnancyDueSoonAlerts;
  final bool healingCompleteAlerts;
  final bool recoveryCompleteAlerts;

  AppSettings copyWith({
    bool? audioEnabled,
    bool? effectsEnabled,
    bool? backgroundAudioEnabled,
    double? masterVolume,
    double? effectsVolume,
    double? backgroundVolume,
    bool? hapticsEnabled,
    bool? compactHorseCards,
    bool? breedingTimerAlerts,
    bool? birthReadyAlerts,
    bool? pregnancyDueSoonAlerts,
    bool? healingCompleteAlerts,
    bool? recoveryCompleteAlerts,
  }) {
    return AppSettings(
      audioEnabled: audioEnabled ?? this.audioEnabled,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      backgroundAudioEnabled:
          backgroundAudioEnabled ?? this.backgroundAudioEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
      effectsVolume: effectsVolume ?? this.effectsVolume,
      backgroundVolume: backgroundVolume ?? this.backgroundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      compactHorseCards: compactHorseCards ?? this.compactHorseCards,
      breedingTimerAlerts: breedingTimerAlerts ?? this.breedingTimerAlerts,
      birthReadyAlerts: birthReadyAlerts ?? this.birthReadyAlerts,
      pregnancyDueSoonAlerts:
          pregnancyDueSoonAlerts ?? this.pregnancyDueSoonAlerts,
      healingCompleteAlerts:
          healingCompleteAlerts ?? this.healingCompleteAlerts,
      recoveryCompleteAlerts:
          recoveryCompleteAlerts ?? this.recoveryCompleteAlerts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audioEnabled': audioEnabled,
      'effectsEnabled': effectsEnabled,
      'backgroundAudioEnabled': backgroundAudioEnabled,
      'masterVolume': masterVolume,
      'effectsVolume': effectsVolume,
      'backgroundVolume': backgroundVolume,
      'hapticsEnabled': hapticsEnabled,
      'compactHorseCards': compactHorseCards,
      'breedingTimerAlerts': breedingTimerAlerts,
      'birthReadyAlerts': birthReadyAlerts,
      'pregnancyDueSoonAlerts': pregnancyDueSoonAlerts,
      'healingCompleteAlerts': healingCompleteAlerts,
      'recoveryCompleteAlerts': recoveryCompleteAlerts,
    };
  }

  static AppSettings fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      audioEnabled: json['audioEnabled'] as bool? ?? defaults.audioEnabled,
      effectsEnabled:
          json['effectsEnabled'] as bool? ?? defaults.effectsEnabled,
      backgroundAudioEnabled:
          json['backgroundAudioEnabled'] as bool? ??
          defaults.backgroundAudioEnabled,
      masterVolume: _volumeFromJson(
        json['masterVolume'],
        defaults.masterVolume,
      ),
      effectsVolume: _volumeFromJson(
        json['effectsVolume'],
        defaults.effectsVolume,
      ),
      backgroundVolume: _volumeFromJson(
        json['backgroundVolume'],
        defaults.backgroundVolume,
      ),
      hapticsEnabled:
          json['hapticsEnabled'] as bool? ?? defaults.hapticsEnabled,
      compactHorseCards:
          json['compactHorseCards'] as bool? ?? defaults.compactHorseCards,
      breedingTimerAlerts:
          json['breedingTimerAlerts'] as bool? ?? defaults.breedingTimerAlerts,
      birthReadyAlerts:
          json['birthReadyAlerts'] as bool? ?? defaults.birthReadyAlerts,
      pregnancyDueSoonAlerts:
          json['pregnancyDueSoonAlerts'] as bool? ??
          defaults.pregnancyDueSoonAlerts,
      healingCompleteAlerts:
          json['healingCompleteAlerts'] as bool? ??
          defaults.healingCompleteAlerts,
      recoveryCompleteAlerts:
          json['recoveryCompleteAlerts'] as bool? ??
          defaults.recoveryCompleteAlerts,
    );
  }

  static double _volumeFromJson(dynamic raw, double fallback) {
    if (raw is! num) {
      return fallback;
    }
    return raw.toDouble().clamp(0, 1);
  }
}

class SettingsRepository {
  const SettingsRepository();

  static const int _saveVersion = 1;

  Future<AppSettings> loadSettings(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawSettings = prefs.getString(_settingsKey(accountId));
    if (rawSettings == null || rawSettings.isEmpty) {
      return AppSettings.defaults();
    }

    try {
      final decoded = jsonDecode(rawSettings);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != _saveVersion) {
        return AppSettings.defaults();
      }
      final settings = decoded['settings'];
      if (settings is! Map<String, dynamic>) {
        return AppSettings.defaults();
      }
      return AppSettings.fromJson(settings);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveSettings(String accountId, AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'version': _saveVersion,
      'settings': settings.toJson(),
    });
    await prefs.setString(_settingsKey(accountId), encoded);
  }

  String _settingsKey(String accountId) =>
      'pivot_horses.app_settings.v1.$accountId';
}
