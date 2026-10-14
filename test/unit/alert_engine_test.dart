import 'package:doodledry/features/alerts/data/models/alert_model.dart';
import 'package:doodledry/features/alerts/data/repositories/alert_repository.dart';
import 'package:doodledry/features/settings/data/models/monitoring_thresholds.dart';
import 'package:doodledry/shared/models/baby_sensor_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alert Engine & Threshold Evaluation Tests', () {
    late AlertRepository alertRepo;
    final thresholds = MonitoringThresholds(
      minHeartRate: 90.0,
      maxHeartRate: 170.0,
      minSpo2: 94.0,
      minTemperatureCelsius: 36.0,
      maxTemperatureCelsius: 37.8,
      lowBatteryThreshold: 20,
      fallAlertEnabled: true,
    );

    setUp(() {
      alertRepo = AlertRepository();
    });

    test('should trigger critical alert immediately upon fall event detection',
        () {
      final fallData = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        fallDetected: true,
        accelerationX: 14.5,
        accelerationY: -8.2,
        accelerationZ: -3.1,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final triggered = alertRepo.evaluateVitals(fallData, thresholds);

      expect(
          triggered.any((a) => a.alertType == AlertType.fallDetected), isTrue);
      final fallAlert =
          triggered.firstWhere((a) => a.alertType == AlertType.fallDetected);
      expect(fallAlert.severity, equals(AlertSeverity.critical));
    });

    test('should trigger warning when heart rate exceeds max threshold', () {
      final highHrData = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        heartRate: 175.0, // Above max 170
        spo2: 98.0,
        temperature: 36.8,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final triggered = alertRepo.evaluateVitals(highHrData, thresholds);

      expect(
          triggered.any((a) => a.alertType == AlertType.heartRateHigh), isTrue);
    });

    test('should trigger low oxygen warning when SpO2 is below threshold', () {
      final lowO2Data = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        heartRate: 125.0,
        spo2: 91.0, // Below min 94
        temperature: 36.8,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final triggered = alertRepo.evaluateVitals(lowO2Data, thresholds);

      expect(triggered.any((a) => a.alertType == AlertType.spo2Low), isTrue);
    });

    test('should not trigger alerts for normal resting vitals', () {
      final normalData = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        heartRate: 125.0,
        spo2: 98.0,
        temperature: 36.8,
        fallDetected: false,
        batteryPercentage: 85,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final triggered = alertRepo.evaluateVitals(normalData, thresholds);
      expect(triggered.isEmpty, isTrue);
    });

    test('does not classify MLX90614 surface temperature as fever', () {
      final objectTemperature = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        sensorModel: 'MLX90614_IR_OBJECT',
        temperature: 39.5,
        temperatureValid: true,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final triggered = alertRepo.evaluateVitals(objectTemperature, thresholds);
      expect(triggered.any((a) => a.alertType == AlertType.temperatureHigh),
          isFalse);
    });
  });
}
