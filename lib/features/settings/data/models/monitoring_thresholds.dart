/// Configurable monitoring thresholds for the DOODLEDRY baby monitoring system.
/// 
/// [NOTE]: These are customizable caregiver monitoring parameters, NOT fixed medical diagnostic standards.
class MonitoringThresholds {
  final double minHeartRate; // BPM (Default prototype: 90)
  final double maxHeartRate; // BPM (Default prototype: 170)
  
  final double minSpo2; // % (Default prototype: 94)
  
  final double minTemperatureCelsius; // °C (Default prototype: 36.0)
  final double maxTemperatureCelsius; // °C (Default prototype: 37.8)

  final int lowBatteryThreshold; // % (Default prototype: 20)
  final bool fallAlertEnabled;
  final bool disconnectionAlertEnabled;

  const MonitoringThresholds({
    this.minHeartRate = 90.0,
    this.maxHeartRate = 170.0,
    this.minSpo2 = 94.0,
    this.minTemperatureCelsius = 36.0,
    this.maxTemperatureCelsius = 37.8,
    this.lowBatteryThreshold = 20,
    this.fallAlertEnabled = true,
    this.disconnectionAlertEnabled = true,
  });

  /// Default factory settings
  factory MonitoringThresholds.defaults() => const MonitoringThresholds();

  factory MonitoringThresholds.fromJson(Map<String, dynamic> json) {
    return MonitoringThresholds(
      minHeartRate: (json['minHeartRate'] as num?)?.toDouble() ?? 90.0,
      maxHeartRate: (json['maxHeartRate'] as num?)?.toDouble() ?? 170.0,
      minSpo2: (json['minSpo2'] as num?)?.toDouble() ?? 94.0,
      minTemperatureCelsius: (json['minTemperatureCelsius'] as num?)?.toDouble() ?? 36.0,
      maxTemperatureCelsius: (json['maxTemperatureCelsius'] as num?)?.toDouble() ?? 37.8,
      lowBatteryThreshold: (json['lowBatteryThreshold'] as num?)?.toInt() ?? 20,
      fallAlertEnabled: json['fallAlertEnabled'] as bool? ?? true,
      disconnectionAlertEnabled: json['disconnectionAlertEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minHeartRate': minHeartRate,
      'maxHeartRate': maxHeartRate,
      'minSpo2': minSpo2,
      'minTemperatureCelsius': minTemperatureCelsius,
      'maxTemperatureCelsius': maxTemperatureCelsius,
      'lowBatteryThreshold': lowBatteryThreshold,
      'fallAlertEnabled': fallAlertEnabled,
      'disconnectionAlertEnabled': disconnectionAlertEnabled,
    };
  }

  MonitoringThresholds copyWith({
    double? minHeartRate,
    double? maxHeartRate,
    double? minSpo2,
    double? minTemperatureCelsius,
    double? maxTemperatureCelsius,
    int? lowBatteryThreshold,
    bool? fallAlertEnabled,
    bool? disconnectionAlertEnabled,
  }) {
    return MonitoringThresholds(
      minHeartRate: minHeartRate ?? this.minHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      minSpo2: minSpo2 ?? this.minSpo2,
      minTemperatureCelsius: minTemperatureCelsius ?? this.minTemperatureCelsius,
      maxTemperatureCelsius: maxTemperatureCelsius ?? this.maxTemperatureCelsius,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      fallAlertEnabled: fallAlertEnabled ?? this.fallAlertEnabled,
      disconnectionAlertEnabled: disconnectionAlertEnabled ?? this.disconnectionAlertEnabled,
    );
  }
}
