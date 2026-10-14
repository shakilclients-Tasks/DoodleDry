import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/settings/data/models/monitoring_thresholds.dart';

/// Evaluator helper to classify vital statuses and format for display
class VitalsEvaluator {
  /// Format temperature according to selected unit
  static String formatTemperature(double? tempCelsius, {required bool isFahrenheit, int fractionDigits = 1}) {
    if (tempCelsius == null) return '--';
    if (isFahrenheit) {
      final fahrenheit = (tempCelsius * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(fractionDigits)} °F';
    }
    return '${tempCelsius.toStringAsFixed(fractionDigits)} °C';
  }

  /// Get status color for Heart Rate based on thresholds
  static Color getHeartRateColor(double? hr, MonitoringThresholds thresholds) {
    if (hr == null) return AppColors.textMutedLight;
    if (hr < thresholds.minHeartRate || hr > thresholds.maxHeartRate) {
      return AppColors.danger;
    }
    if (hr < (thresholds.minHeartRate + 10) || hr > (thresholds.maxHeartRate - 10)) {
      return AppColors.warning;
    }
    return AppColors.heartRate;
  }

  /// Get status color for SpO2
  static Color getSpo2Color(double? spo2, MonitoringThresholds thresholds) {
    if (spo2 == null) return AppColors.textMutedLight;
    if (spo2 < thresholds.minSpo2) {
      return AppColors.danger;
    }
    if (spo2 < (thresholds.minSpo2 + 3)) {
      return AppColors.warning;
    }
    return AppColors.spo2;
  }

  /// Get status color for Temperature
  static Color getTemperatureColor(double? temp, MonitoringThresholds thresholds) {
    if (temp == null) return AppColors.textMutedLight;
    if (temp < thresholds.minTemperatureCelsius || temp > thresholds.maxTemperatureCelsius) {
      return AppColors.danger;
    }
    if (temp > (thresholds.maxTemperatureCelsius - 0.5) || temp < (thresholds.minTemperatureCelsius + 0.5)) {
      return AppColors.warning;
    }
    return AppColors.temperature;
  }

  /// Get battery status color
  static Color getBatteryColor(int? battery) {
    if (battery == null) return AppColors.textMutedLight;
    if (battery <= 15) return AppColors.batteryCritical;
    if (battery <= 30) return AppColors.batteryLow;
    return AppColors.batteryGood;
  }

  /// Get battery descriptive state
  static String getBatteryStatusText(int? battery) {
    if (battery == null) return 'Battery unavailable';
    if (battery <= 15) return 'Critical Battery ($battery%)';
    if (battery <= 30) return 'Low Battery ($battery%)';
    return 'Normal ($battery%)';
  }
}
