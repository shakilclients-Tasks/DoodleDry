import 'sensor_status.dart';

/// Unified sensor data model representing physiological & environmental readings
/// captured by the DOODLEDRY wearable hardware module.
class BabySensorData {
  static const Object _unset = Object();
  final String deviceId;
  final String babyId;

  // Physiological vitals
  final double? heartRate;
  final double? spo2;
  final double?
      temperature; // Measured IR object/surface temperature in Celsius, not core body temperature.
  final double?
      ambientTemperature; // MLX90614 sensor ambient temperature in Celsius.
  final String? sensorModel; // e.g. 'MLX90614'
  final bool? fingerDetected;
  final bool? heartRateValid;
  final bool? spo2Valid;
  final bool? temperatureValid;
  final bool? motionValid;
  final bool? poorSignal;
  final Map<String, dynamic>? diagnostics;

  // 3-Axis Accelerometer Motion Data
  final double? accelerationX;
  final double? accelerationY;
  final double? accelerationZ;

  // Safety & Activity
  final bool? fallDetected;
  final String?
      activityStatus; // 'sleeping', 'awake', 'active', 'restless', 'unknown'

  // Device telemetry
  final DateTime timestamp;
  final int? batteryPercentage;

  // Status flags
  final bool isDeviceConnected;
  final bool isSensorDataValid;
  final bool isSimulation;

  // Individual Sensor States
  final SensorState heartRateState;
  final SensorState spo2State;
  final SensorState temperatureState;
  final SensorState motionState;
  final SensorDataQuality dataQuality;

  const BabySensorData({
    required this.deviceId,
    required this.babyId,
    this.heartRate,
    this.spo2,
    this.temperature,
    this.ambientTemperature,
    this.sensorModel,
    this.fingerDetected,
    this.heartRateValid,
    this.spo2Valid,
    this.temperatureValid,
    this.motionValid,
    this.poorSignal,
    this.diagnostics,
    this.accelerationX,
    this.accelerationY,
    this.accelerationZ,
    this.fallDetected,
    this.activityStatus,
    required this.timestamp,
    this.batteryPercentage,
    this.isDeviceConnected = false,
    this.isSensorDataValid = true,
    this.isSimulation = false,
    this.heartRateState = SensorState.active,
    this.spo2State = SensorState.active,
    this.temperatureState = SensorState.active,
    this.motionState = SensorState.active,
    this.dataQuality = SensorDataQuality.valid,
  });

  /// Factory for disconnected or waiting state
  factory BabySensorData.disconnected({String? deviceId, String? babyId}) {
    return BabySensorData(
      deviceId: deviceId ?? '--',
      babyId: babyId ?? 'unassigned',
      timestamp: DateTime.now(),
      isDeviceConnected: false,
      isSensorDataValid: false,
      heartRateState: SensorState.noData,
      spo2State: SensorState.noData,
      temperatureState: SensorState.noData,
      motionState: SensorState.noData,
      dataQuality: SensorDataQuality.missing,
    );
  }

  /// Create an instance from a JSON packet received over BLE or Cloud
  factory BabySensorData.fromJson(Map<String, dynamic> json,
      {bool isSimulation = false}) {
    // The app's monotonic receive time controls freshness; a device clock may be unset.
    final parsedTimestamp = DateTime.now();

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      final number =
          val is num ? val.toDouble() : double.tryParse(val.toString());
      return number != null && number.isFinite ? number : null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      return val.toString().toLowerCase() == 'true' || val.toString() == '1';
    }

    final hr = parseDouble(json['heartRate'] ?? json['hr']);
    final o2 = parseDouble(json['spo2'] ?? json['oxygen']);
    final temp = parseDouble(json['temperature'] ?? json['temp']);
    final ambTemp = parseDouble(
        json['ambientTemp'] ?? json['ambientTemperature'] ?? json['roomTemp']);
    final sModel =
        json['sensorModel']?.toString() ?? (temp != null ? 'MLX90614' : null);
    final ax = parseDouble(json['accelerationX'] ?? json['ax']);
    final ay = parseDouble(json['accelerationY'] ?? json['ay']);
    final az = parseDouble(json['accelerationZ'] ?? json['az']);
    final fall = parseBool(json['fallDetected'] ?? json['fall']);
    final act = (json['activityStatus'] ?? json['activity'])
            ?.toString()
            .toLowerCase() ??
        'unknown';
    final rawBattery = parseInt(json['batteryPercentage'] ?? json['battery']);
    final batt = rawBattery != null && rawBattery >= 0 && rawBattery <= 100
        ? rawBattery
        : null;
    final devId = json['deviceId']?.toString() ?? '--';
    final bId = json['babyId']?.toString() ?? 'baby_default';

    final finger = json['fingerDetected'] == null
        ? null
        : parseBool(json['fingerDetected']);
    final hrValid = json['heartRateValid'] == null
        ? null
        : parseBool(json['heartRateValid']);
    final o2Valid =
        json['spo2Valid'] == null ? null : parseBool(json['spo2Valid']);
    final tempValid = json['temperatureValid'] == null
        ? null
        : parseBool(json['temperatureValid']);
    final tempMeasuring = parseBool(json['temperatureMeasuring']);
    final motionValid =
        json['motionValid'] == null ? null : parseBool(json['motionValid']);
    final poor = parseBool(json['poorSignal']);
    final hasHr = hr != null && hr > 0 && finger != false && hrValid != false;
    final hasO2 = o2 != null && o2 > 0 && finger != false && o2Valid != false;
    final hasTemp = temp != null && tempValid != false;
    final hasMotion = motionValid != false &&
        (const {'still', 'moving', 'active', 'sleeping', 'awake', 'restless'}
                .contains(act) ||
            (ax != null && ay != null && az != null));

    return BabySensorData(
      deviceId: devId,
      babyId: bId,
      heartRate: hasHr ? hr : null,
      spo2: hasO2 ? o2 : null,
      temperature: hasTemp ? temp : null,
      ambientTemperature: ambTemp,
      sensorModel: sModel,
      fingerDetected: finger,
      heartRateValid: hrValid,
      spo2Valid: o2Valid,
      temperatureValid: tempValid,
      motionValid: motionValid,
      poorSignal: poor,
      diagnostics: json['debug'] is Map<String, dynamic>
          ? json['debug'] as Map<String, dynamic>
          : null,
      accelerationX: ax,
      accelerationY: ay,
      accelerationZ: az,
      fallDetected: fall,
      activityStatus: hasMotion ? act : 'unknown',
      timestamp: parsedTimestamp,
      batteryPercentage: batt,
      isDeviceConnected: true,
      isSensorDataValid: hasHr || hasO2 || hasTemp || hasMotion,
      isSimulation: isSimulation,
      heartRateState: hasHr
          ? SensorState.active
          : finger != true
              ? SensorState.noData
              : poor
                  ? SensorState.poorSignal
                  : SensorState.measuring,
      spo2State: hasO2
          ? SensorState.active
          : finger != true
              ? SensorState.noData
              : poor
                  ? SensorState.poorSignal
                  : SensorState.measuring,
      temperatureState: hasTemp
          ? SensorState.active
          : tempMeasuring
              ? SensorState.measuring
              : tempValid == false
                  ? SensorState.error
                  : SensorState.noData,
      motionState: hasMotion ? SensorState.active : SensorState.noData,
      dataQuality: SensorDataQuality.valid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'babyId': babyId,
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'ambientTemperature': ambientTemperature,
      'sensorModel': sensorModel,
      'fingerDetected': fingerDetected,
      'heartRateValid': heartRateValid,
      'spo2Valid': spo2Valid,
      'temperatureValid': temperatureValid,
      'motionValid': motionValid,
      'poorSignal': poorSignal,
      'debug': diagnostics,
      'accelerationX': accelerationX,
      'accelerationY': accelerationY,
      'accelerationZ': accelerationZ,
      'fallDetected': fallDetected,
      'activityStatus': activityStatus,
      'timestamp': timestamp.toIso8601String(),
      'batteryPercentage': batteryPercentage,
      'isDeviceConnected': isDeviceConnected,
      'isSensorDataValid': isSensorDataValid,
      'isSimulation': isSimulation,
      'heartRateState': heartRateState.name,
      'spo2State': spo2State.name,
      'temperatureState': temperatureState.name,
      'motionState': motionState.name,
      'dataQuality': dataQuality.name,
    };
  }

  BabySensorData copyWith({
    String? deviceId,
    String? babyId,
    Object? heartRate = _unset,
    Object? spo2 = _unset,
    Object? temperature = _unset,
    double? ambientTemperature,
    String? sensorModel,
    bool? fingerDetected,
    bool? heartRateValid,
    bool? spo2Valid,
    bool? temperatureValid,
    bool? motionValid,
    bool? poorSignal,
    Map<String, dynamic>? diagnostics,
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
    bool? fallDetected,
    String? activityStatus,
    DateTime? timestamp,
    int? batteryPercentage,
    bool? isDeviceConnected,
    bool? isSensorDataValid,
    bool? isSimulation,
    SensorState? heartRateState,
    SensorState? spo2State,
    SensorState? temperatureState,
    SensorState? motionState,
    SensorDataQuality? dataQuality,
  }) {
    return BabySensorData(
      deviceId: deviceId ?? this.deviceId,
      babyId: babyId ?? this.babyId,
      heartRate:
          identical(heartRate, _unset) ? this.heartRate : heartRate as double?,
      spo2: identical(spo2, _unset) ? this.spo2 : spo2 as double?,
      temperature: identical(temperature, _unset)
          ? this.temperature
          : temperature as double?,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      sensorModel: sensorModel ?? this.sensorModel,
      fingerDetected: fingerDetected ?? this.fingerDetected,
      heartRateValid: heartRateValid ?? this.heartRateValid,
      spo2Valid: spo2Valid ?? this.spo2Valid,
      temperatureValid: temperatureValid ?? this.temperatureValid,
      motionValid: motionValid ?? this.motionValid,
      poorSignal: poorSignal ?? this.poorSignal,
      diagnostics: diagnostics ?? this.diagnostics,
      accelerationX: accelerationX ?? this.accelerationX,
      accelerationY: accelerationY ?? this.accelerationY,
      accelerationZ: accelerationZ ?? this.accelerationZ,
      fallDetected: fallDetected ?? this.fallDetected,
      activityStatus: activityStatus ?? this.activityStatus,
      timestamp: timestamp ?? this.timestamp,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      isDeviceConnected: isDeviceConnected ?? this.isDeviceConnected,
      isSensorDataValid: isSensorDataValid ?? this.isSensorDataValid,
      isSimulation: isSimulation ?? this.isSimulation,
      heartRateState: heartRateState ?? this.heartRateState,
      spo2State: spo2State ?? this.spo2State,
      temperatureState: temperatureState ?? this.temperatureState,
      motionState: motionState ?? this.motionState,
      dataQuality: dataQuality ?? this.dataQuality,
    );
  }

  /// Helper: Check if data is stale (e.g. older than 10 seconds)
  bool isStale({Duration maxAge = const Duration(seconds: 10)}) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  /// Temperature converted to Fahrenheit
  double? get temperatureInFahrenheit {
    if (temperature == null) return null;
    return (temperature! * 9 / 5) + 32;
  }

  /// Ambient Temperature converted to Fahrenheit
  double? get ambientTemperatureInFahrenheit {
    if (ambientTemperature == null) return null;
    return (ambientTemperature! * 9 / 5) + 32;
  }

  /// Formatted activity status label
  String get formattedActivity {
    switch (activityStatus?.toLowerCase()) {
      case 'sleeping':
        return 'Sleeping';
      case 'awake':
        return 'Awake';
      case 'active':
        return 'Active';
      case 'restless':
        return 'Restless';
      case 'still':
        return 'Still';
      case 'moving':
        return 'Moving';
      default:
        return 'Unknown';
    }
  }
}
