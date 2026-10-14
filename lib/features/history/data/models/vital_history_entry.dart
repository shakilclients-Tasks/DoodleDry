/// Point-in-time sensor entry for historical trend plotting and analytics
class VitalHistoryEntry {
  final DateTime timestamp;
  final double? heartRate;
  final double? spo2;
  final double? temperature; // MLX90614 object temperature in Celsius
  final String activityStatus; // sleeping, awake, active, restless
  final bool isSimulation;

  const VitalHistoryEntry({
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.activityStatus,
    this.isSimulation = false,
  });

  factory VitalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return VitalHistoryEntry(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      heartRate: (json['heartRate'] as num?)?.toDouble(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      activityStatus: json['activityStatus'] as String? ?? 'unknown',
      isSimulation: json['isSimulation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'activityStatus': activityStatus,
      'isSimulation': isSimulation,
    };
  }
}
