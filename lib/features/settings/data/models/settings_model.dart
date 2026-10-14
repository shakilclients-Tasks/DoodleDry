import 'monitoring_thresholds.dart';
import 'package:flutter/foundation.dart';

/// User and Application settings
class AppSettings {
  final bool isFahrenheit; // false = Celsius, true = Fahrenheit
  final bool isDarkMode;
  final bool isSimulationMode;
  final bool notificationsEnabled;
  final bool soundAlertsEnabled;
  final bool cloudSyncEnabled;
  final MonitoringThresholds thresholds;

  const AppSettings({
    this.isFahrenheit = false,
    this.isDarkMode = false,
    this.isSimulationMode = false, // Defaults to false for real hardware BLE
    this.notificationsEnabled = true,
    this.soundAlertsEnabled = true,
    this.cloudSyncEnabled = true,
    this.thresholds = const MonitoringThresholds(),
  });

  factory AppSettings.defaults() => const AppSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isFahrenheit: json['isFahrenheit'] as bool? ?? false,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      isSimulationMode: kDebugMode && (json['isSimulationMode'] as bool? ?? false),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundAlertsEnabled: json['soundAlertsEnabled'] as bool? ?? true,
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? true,
      thresholds: json['thresholds'] != null
          ? MonitoringThresholds.fromJson(json['thresholds'] as Map<String, dynamic>)
          : const MonitoringThresholds(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFahrenheit': isFahrenheit,
      'isDarkMode': isDarkMode,
      'isSimulationMode': isSimulationMode,
      'notificationsEnabled': notificationsEnabled,
      'soundAlertsEnabled': soundAlertsEnabled,
      'cloudSyncEnabled': cloudSyncEnabled,
      'thresholds': thresholds.toJson(),
    };
  }

  AppSettings copyWith({
    bool? isFahrenheit,
    bool? isDarkMode,
    bool? isSimulationMode,
    bool? notificationsEnabled,
    bool? soundAlertsEnabled,
    bool? cloudSyncEnabled,
    MonitoringThresholds? thresholds,
  }) {
    return AppSettings(
      isFahrenheit: isFahrenheit ?? this.isFahrenheit,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isSimulationMode: isSimulationMode ?? this.isSimulationMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      thresholds: thresholds ?? this.thresholds,
    );
  }
}
