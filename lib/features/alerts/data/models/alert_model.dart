import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Severity levels for DOODLEDRY safety alerts
enum AlertSeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Information';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return AppColors.info;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.critical:
        return AppColors.danger;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AlertSeverity.info:
        return AppColors.infoBg;
      case AlertSeverity.warning:
        return AppColors.warningBg;
      case AlertSeverity.critical:
        return AppColors.dangerBg;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.critical:
        return Icons.crisis_alert_rounded;
    }
  }
}

/// Category types for alerts
enum AlertType {
  heartRateHigh,
  heartRateLow,
  spo2Low,
  temperatureHigh,
  temperatureLow,
  fallDetected,
  deviceDisconnected,
  sensorFailure,
  batteryLow,
  syncError;

  String get displayName {
    switch (this) {
      case AlertType.heartRateHigh:
        return 'Elevated Heart Rate';
      case AlertType.heartRateLow:
        return 'Low Heart Rate';
      case AlertType.spo2Low:
        return 'Low Oxygen (SpO₂)';
      case AlertType.temperatureHigh:
        return 'High Temperature (Fever)';
      case AlertType.temperatureLow:
        return 'Low Temperature';
      case AlertType.fallDetected:
        return 'Sudden Fall / Impact';
      case AlertType.deviceDisconnected:
        return 'Wearable Disconnected';
      case AlertType.sensorFailure:
        return 'Sensor Quality Issue';
      case AlertType.batteryLow:
        return 'Low Battery';
      case AlertType.syncError:
        return 'Cloud Sync Error';
    }
  }
}

/// Alert Record Model
class AlertModel {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertType alertType;
  final String? sensorType;
  final String? readingValue;
  final DateTime timestamp;
  final String deviceId;
  final bool isSeen;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.alertType,
    this.sensorType,
    this.readingValue,
    required this.timestamp,
    required this.deviceId,
    this.isSeen = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Alert',
      message: json['message'] as String? ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      alertType: AlertType.values.firstWhere(
        (e) => e.name == json['alertType'],
        orElse: () => AlertType.sensorFailure,
      ),
      sensorType: json['sensorType'] as String?,
      readingValue: json['readingValue'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deviceId: json['deviceId'] as String? ?? 'DOODLEDRY-001',
      isSeen: json['isSeen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity.name,
      'alertType': alertType.name,
      'sensorType': sensorType,
      'readingValue': readingValue,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'isSeen': isSeen,
    };
  }

  AlertModel copyWith({
    String? id,
    String? title,
    String? message,
    AlertSeverity? severity,
    AlertType? alertType,
    String? sensorType,
    String? readingValue,
    DateTime? timestamp,
    String? deviceId,
    bool? isSeen,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      alertType: alertType ?? this.alertType,
      sensorType: sensorType ?? this.sensorType,
      readingValue: readingValue ?? this.readingValue,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}
