import '../../shared/models/baby_sensor_data.dart';
import '../../shared/models/sensor_status.dart';

/// Validation result with detailed status per sensor
class ValidationResult {
  final bool isValid;
  final SensorDataQuality overallQuality;
  final SensorState heartRateState;
  final SensorState spo2State;
  final SensorState temperatureState;
  final SensorState motionState;
  final List<String> issues;

  const ValidationResult({
    required this.isValid,
    required this.overallQuality,
    required this.heartRateState,
    required this.spo2State,
    required this.temperatureState,
    required this.motionState,
    this.issues = const [],
  });
}

/// Comprehensive validator for incoming sensor readings
class SensorDataValidator {
  // Biological plausibility limits (for sensor health validation, not medical diagnosis)
  static const double minHeartRate = 40.0;
  static const double maxHeartRate = 240.0;

  static const double minSpo2 = 50.0;
  static const double maxSpo2 = 100.0;

  // MLX90614 sends object/surface temperature, which can be below skin range
  // when the sensor is pointed elsewhere. Plausible range here is not a fever test.
  static const double minTempCelsius = -20.0;
  static const double maxTempCelsius = 100.0;

  static const double maxAccelerationMagnitude = 40.0; // m/s^2

  static const Duration staleDataThreshold = Duration(seconds: 5);

  /// Validates a [BabySensorData] instance and returns an updated copy with validated states
  static BabySensorData validateAndSanitize(BabySensorData raw) {
    if (!raw.isDeviceConnected) {
      return raw.copyWith(
        isSensorDataValid: false,
        heartRateState: SensorState.noData,
        spo2State: SensorState.noData,
        temperatureState: SensorState.noData,
        motionState: SensorState.noData,
        dataQuality: SensorDataQuality.missing,
      );
    }

    final issues = <String>[];

    // 1. Check Staleness
    final isStale =
        DateTime.now().difference(raw.timestamp) > staleDataThreshold;
    if (isStale) {
      issues.add(
          "Data timestamp is older than ${staleDataThreshold.inSeconds} seconds.");
    }

    // 2. Validate Heart Rate
    SensorState hrState = raw.heartRateState;
    if (raw.fingerDetected == false || raw.heartRateValid == false) {
      hrState = raw.fingerDetected == false
          ? SensorState.noData
          : raw.poorSignal == true
              ? SensorState.poorSignal
              : SensorState.measuring;
    } else if (raw.heartRate == null || raw.heartRate == 0) {
      hrState = raw.fingerDetected == true
          ? SensorState.measuring
          : SensorState.noData;
    } else if (!raw.heartRate!.isFinite ||
        raw.heartRate! < minHeartRate ||
        raw.heartRate! > maxHeartRate) {
      hrState = SensorState.error;
      issues.add(
          "Heart rate reading (${raw.heartRate} BPM) outside plausible physical range.");
    }

    // 3. Validate SpO2
    SensorState o2State = raw.spo2State;
    if (raw.fingerDetected == false || raw.spo2Valid == false) {
      o2State = raw.fingerDetected == false
          ? SensorState.noData
          : raw.poorSignal == true
              ? SensorState.poorSignal
              : SensorState.measuring;
    } else if (raw.spo2 == null || raw.spo2 == 0) {
      o2State = raw.fingerDetected == true
          ? SensorState.measuring
          : SensorState.noData;
    } else if (!raw.spo2!.isFinite ||
        raw.spo2! < minSpo2 ||
        raw.spo2! > maxSpo2) {
      o2State = SensorState.error;
      issues.add("SpO2 reading (${raw.spo2}%) outside valid range.");
    }

    // 4. Validate Temperature
    SensorState tempState = raw.temperatureState;
    if (raw.temperatureValid == false) {
      tempState = raw.temperatureState == SensorState.measuring
          ? SensorState.measuring
          : SensorState.error;
    } else if (raw.temperature == null) {
      tempState = SensorState.noData;
    } else if (!raw.temperature!.isFinite ||
        raw.temperature! < minTempCelsius ||
        raw.temperature! > maxTempCelsius) {
      tempState = SensorState.error;
      issues.add(
          "IR object temperature (${raw.temperature}°C) outside supported range.");
    }

    // 5. Validate Motion
    SensorState motionState = raw.motionState;
    if (raw.motionValid == false || raw.activityStatus == 'unknown') {
      motionState = SensorState.noData;
    }
    if (isStale) {
      hrState = o2State = tempState = motionState = SensorState.noData;
    }

    // 6. Overall Quality determination
    SensorDataQuality quality;
    if (isStale) {
      quality = SensorDataQuality.stale;
    } else if (hrState == SensorState.error ||
        o2State == SensorState.error ||
        tempState == SensorState.error) {
      quality = SensorDataQuality.sensorError;
    } else if (hrState == SensorState.noData &&
        o2State == SensorState.noData &&
        tempState == SensorState.noData &&
        motionState == SensorState.noData) {
      quality = SensorDataQuality.missing;
    } else if (issues.isNotEmpty) {
      quality = SensorDataQuality.invalid;
    } else {
      quality = SensorDataQuality.valid;
    }

    final isValid = quality == SensorDataQuality.valid;

    return raw.copyWith(
      heartRate:
          !isStale && hrState == SensorState.active ? raw.heartRate : null,
      spo2: !isStale && o2State == SensorState.active ? raw.spo2 : null,
      temperature:
          !isStale && tempState == SensorState.active ? raw.temperature : null,
      isSensorDataValid: isValid,
      heartRateState: hrState,
      spo2State: o2State,
      temperatureState: tempState,
      motionState: motionState,
      dataQuality: quality,
    );
  }
}
