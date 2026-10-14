import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../settings/data/models/monitoring_thresholds.dart';
import '../models/alert_model.dart';

/// Alert Repository and Engine for evaluating sensor readings and managing alert logs
class AlertRepository {
  final List<AlertModel> _alerts = [];
  final StreamController<List<AlertModel>> _alertsStreamController =
      StreamController<List<AlertModel>>.broadcast();

  final Map<AlertType, DateTime> _lastAlertTrigger = {};
  static const Duration _alertCooldown = Duration(seconds: 45);
  final Uuid _uuid = const Uuid();

  AlertRepository();

  Stream<List<AlertModel>> get alertsStream => _alertsStreamController.stream;
  List<AlertModel> get currentAlerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.isSeen).length;

  /// Evaluates incoming sensor data against active thresholds and dispatches alerts
  List<AlertModel> evaluateVitals(BabySensorData data, MonitoringThresholds thresholds) {
    final now = DateTime.now();
    final newAlerts = <AlertModel>[];

    bool shouldTrigger(AlertType type, {Duration customCooldown = _alertCooldown}) {
      final last = _lastAlertTrigger[type];
      if (last == null || now.difference(last) > customCooldown) {
        _lastAlertTrigger[type] = now;
        return true;
      }
      return false;
    }

    // 1. Critical: Sudden Fall Detection
    if (data.fallDetected == true && thresholds.fallAlertEnabled) {
      if (shouldTrigger(AlertType.fallDetected, customCooldown: const Duration(seconds: 20))) {
        final alert = AlertModel(
          id: _uuid.v4(),
          title: "Sudden Movement / Impact Detected",
          message: "The wearable sensor detected a sharp acceleration change. Please inspect the baby immediately.",
          severity: AlertSeverity.critical,
          alertType: AlertType.fallDetected,
          sensorType: "Motion / Accelerometer",
          readingValue: "X: ${data.accelerationX}, Y: ${data.accelerationY}, Z: ${data.accelerationZ} m/s²",
          timestamp: now,
          deviceId: data.deviceId,
          isSeen: false,
        );
        newAlerts.add(alert);
      }
    }

    // 2. Heart Rate Threshold Check (Only evaluate if sensor has active skin contact > 30 BPM)
    if (data.heartRate != null && data.heartRate! > 30.0 && data.isDeviceConnected) {
      if (data.heartRate! > thresholds.maxHeartRate) {
        if (shouldTrigger(AlertType.heartRateHigh)) {
          final isCritical = data.heartRate! > (thresholds.maxHeartRate + 25);
          final alert = AlertModel(
            id: _uuid.v4(),
            title: isCritical ? "Critical: High Heart Rate" : "Elevated Heart Rate Warning",
            message: "Heart rate is ${data.heartRate!.toStringAsFixed(0)} BPM, exceeding configured limit of ${thresholds.maxHeartRate.toStringAsFixed(0)} BPM.",
            severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
            alertType: AlertType.heartRateHigh,
            sensorType: "Heart Rate",
            readingValue: "${data.heartRate!.toStringAsFixed(0)} BPM",
            timestamp: now,
            deviceId: data.deviceId,
            isSeen: false,
          );
          newAlerts.add(alert);
        }
      } else if (data.heartRate! < thresholds.minHeartRate) {
        if (shouldTrigger(AlertType.heartRateLow)) {
          final isCritical = data.heartRate! < (thresholds.minHeartRate - 20);
          final alert = AlertModel(
            id: _uuid.v4(),
            title: isCritical ? "Critical: Low Heart Rate" : "Low Heart Rate Warning",
            message: "Heart rate is ${data.heartRate!.toStringAsFixed(0)} BPM, below configured threshold of ${thresholds.minHeartRate.toStringAsFixed(0)} BPM.",
            severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
            alertType: AlertType.heartRateLow,
            sensorType: "Heart Rate",
            readingValue: "${data.heartRate!.toStringAsFixed(0)} BPM",
            timestamp: now,
            deviceId: data.deviceId,
            isSeen: false,
          );
          newAlerts.add(alert);
        }
      }
    }

    // 3. SpO2 Threshold Check (Only evaluate if sensor has active skin contact > 40%)
    if (data.spo2 != null && data.spo2! > 40.0 && data.isDeviceConnected) {
      if (data.spo2! < thresholds.minSpo2) {
        if (shouldTrigger(AlertType.spo2Low)) {
          final isCritical = data.spo2! < 90.0;
          final alert = AlertModel(
            id: _uuid.v4(),
            title: isCritical ? "Critical: Low Oxygen Saturation" : "Low SpO₂ Warning",
            message: "Oxygen level is ${data.spo2!.toStringAsFixed(0)}%, below threshold of ${thresholds.minSpo2.toStringAsFixed(0)}%.",
            severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
            alertType: AlertType.spo2Low,
            sensorType: "SpO₂ Sensor",
            readingValue: "${data.spo2!.toStringAsFixed(0)}%",
            timestamp: now,
            deviceId: data.deviceId,
            isSeen: false,
          );
          newAlerts.add(alert);
        }
      }
    }

    // 4. Temperature Threshold Check
    if (data.temperature != null && data.isDeviceConnected) {
      if (data.temperature! > thresholds.maxTemperatureCelsius) {
        if (shouldTrigger(AlertType.temperatureHigh)) {
          final isCritical = data.temperature! >= 39.0;
          final alert = AlertModel(
            id: _uuid.v4(),
            title: isCritical ? "Critical: High Fever Detected" : "Elevated Temperature Warning",
            message: "Body temperature is ${data.temperature!.toStringAsFixed(1)}°C, exceeding configured upper threshold of ${thresholds.maxTemperatureCelsius.toStringAsFixed(1)}°C.",
            severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
            alertType: AlertType.temperatureHigh,
            sensorType: "Temperature Sensor",
            readingValue: "${data.temperature!.toStringAsFixed(1)} °C",
            timestamp: now,
            deviceId: data.deviceId,
            isSeen: false,
          );
          newAlerts.add(alert);
        }
      } else if (data.temperature! < thresholds.minTemperatureCelsius) {
        if (shouldTrigger(AlertType.temperatureLow)) {
          final alert = AlertModel(
            id: _uuid.v4(),
            title: "Low Temperature Reading",
            message: "Body temperature is ${data.temperature!.toStringAsFixed(1)}°C, below threshold of ${thresholds.minTemperatureCelsius.toStringAsFixed(1)}°C.",
            severity: AlertSeverity.warning,
            alertType: AlertType.temperatureLow,
            sensorType: "Temperature Sensor",
            readingValue: "${data.temperature!.toStringAsFixed(1)} °C",
            timestamp: now,
            deviceId: data.deviceId,
            isSeen: false,
          );
          newAlerts.add(alert);
        }
      }
    }

    // 5. Battery Check
    if (data.batteryPercentage != null && data.batteryPercentage! <= thresholds.lowBatteryThreshold) {
      if (shouldTrigger(AlertType.batteryLow, customCooldown: const Duration(minutes: 5))) {
        final alert = AlertModel(
          id: _uuid.v4(),
          title: "Low Wearable Battery",
          message: "Device battery is at ${data.batteryPercentage}%. Please recharge the monitoring module.",
          severity: data.batteryPercentage! <= 10 ? AlertSeverity.critical : AlertSeverity.warning,
          alertType: AlertType.batteryLow,
          sensorType: "Battery",
          readingValue: "${data.batteryPercentage}%",
          timestamp: now,
          deviceId: data.deviceId,
          isSeen: false,
        );
        newAlerts.add(alert);
      }
    }

    if (newAlerts.isNotEmpty) {
      _alerts.insertAll(0, newAlerts);
      // Keep maximum 100 historical alerts
      if (_alerts.length > 100) {
        _alerts.removeRange(100, _alerts.length);
      }
      _alertsStreamController.add(List.from(_alerts));
    }

    return newAlerts;
  }

  void markAsSeen(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isSeen: true);
      _alertsStreamController.add(List.from(_alerts));
    }
  }

  void markAllAsSeen() {
    for (int i = 0; i < _alerts.length; i++) {
      _alerts[i] = _alerts[i].copyWith(isSeen: true);
    }
    _alertsStreamController.add(List.from(_alerts));
  }

  void clearAll() {
    _alerts.clear();
    _alertsStreamController.add([]);
  }

  void dispose() {
    _alertsStreamController.close();
  }
}
