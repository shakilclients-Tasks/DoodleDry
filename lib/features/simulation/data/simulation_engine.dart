import 'dart:async';
import 'dart:math';
import 'package:doodledry/shared/models/baby_sensor_data.dart';
import 'package:doodledry/shared/models/sensor_status.dart';

/// Simulation Engine generating realistic, dynamic, and testable sensor telemetry.
/// 
/// Allows complete testing of vitals charts, alerts, fall detection, battery drops,
/// and connection failures without requiring physical BLE hardware.
class SimulationEngine {
  final StreamController<BabySensorData> _controller = StreamController<BabySensorData>.broadcast();
  Timer? _timer;
  final Random _random = Random();

  // Configurable simulation states
  bool _isConnected = true;
  bool _forceFallDetected = false;
  double? _forcedHeartRate;
  double? _forcedSpo2;
  double? _forcedTemperature;
  int _batteryLevel = 88;
  String _currentActivity = 'sleeping'; // sleeping, awake, active, restless
  double _stepCounter = 0.0;

  // Stream getter
  Stream<BabySensorData> get sensorDataStream => _controller.stream;
  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isConnected => _isConnected;

  void start({Duration interval = const Duration(seconds: 1)}) {
    stop();
    _isConnected = true;
    _timer = Timer.periodic(interval, (_) => _generateAndEmit());
    _generateAndEmit();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  // Simulator Interactive Controls
  void toggleConnection([bool? connected]) {
    _isConnected = connected ?? !_isConnected;
    _generateAndEmit();
  }

  void triggerFallEvent() {
    _forceFallDetected = true;
    _currentActivity = 'restless';
    _generateAndEmit();
    
    // Auto-clear after 15 seconds if not manually reset
    Future.delayed(const Duration(seconds: 15), () {
      if (_forceFallDetected) {
        _forceFallDetected = false;
        _generateAndEmit();
      }
    });
  }

  void clearFallEvent() {
    _forceFallDetected = false;
    _generateAndEmit();
  }

  void setForcedVitals({double? hr, double? spo2, double? temp}) {
    _forcedHeartRate = hr;
    _forcedSpo2 = spo2;
    _forcedTemperature = temp;
    _generateAndEmit();
  }

  void resetToNormal() {
    _forcedHeartRate = null;
    _forcedSpo2 = null;
    _forcedTemperature = null;
    _forceFallDetected = false;
    _batteryLevel = 85;
    _currentActivity = 'sleeping';
    _isConnected = true;
    _generateAndEmit();
  }

  void setActivity(String activity) {
    _currentActivity = activity;
    _generateAndEmit();
  }

  void setBattery(int level) {
    _batteryLevel = level.clamp(0, 100);
    _generateAndEmit();
  }

  void _generateAndEmit() {
    if (!_isConnected) {
      _controller.add(BabySensorData.disconnected(
        deviceId: 'DOODLEDRY-SIM-001',
        babyId: 'baby_leo_001',
      ));
      return;
    }

    _stepCounter += 0.1;

    // 1. Heart Rate (infant resting base ~ 125 BPM + sinusoidal wave + random noise)
    double baseHr = 125.0;
    if (_currentActivity == 'active') baseHr = 145.0;
    if (_currentActivity == 'restless') baseHr = 155.0;
    if (_currentActivity == 'sleeping') baseHr = 118.0;

    double hr = _forcedHeartRate ?? (baseHr + (sin(_stepCounter) * 6.0) + (_random.nextDouble() * 3.0 - 1.5));
    hr = hr.clamp(45.0, 220.0);

    // 2. SpO2 (Normal 97% - 99%)
    double o2 = _forcedSpo2 ?? (98.0 + (sin(_stepCounter * 0.5) * 0.8) + (_random.nextDouble() * 0.6 - 0.3));
    o2 = o2.clamp(70.0, 100.0);

    // 3. Body Temperature (Normal 36.6°C - 37.1°C) via MLX90614 IR
    double temp = _forcedTemperature ?? (36.8 + (sin(_stepCounter * 0.2) * 0.2) + (_random.nextDouble() * 0.1 - 0.05));
    temp = temp.clamp(32.0, 42.0);
    double ambTemp = 24.2 + (sin(_stepCounter * 0.05) * 0.3); // Nursery Room Ambient Temp

    // 4. 3-Axis Accelerometer Motion
    double ax = 0.05 + (_random.nextDouble() * 0.2 - 0.1);
    double ay = -0.08 + (_random.nextDouble() * 0.2 - 0.1);
    double az = 9.81 + (_random.nextDouble() * 0.3 - 0.15); // Gravity vector

    if (_forceFallDetected) {
      ax = (_random.nextDouble() * 25.0 - 12.5);
      ay = (_random.nextDouble() * 25.0 - 12.5);
      az = -2.0 + (_random.nextDouble() * 4.0); // Sudden drop / impact
    } else if (_currentActivity == 'active' || _currentActivity == 'restless') {
      ax += (_random.nextDouble() * 3.0 - 1.5);
      ay += (_random.nextDouble() * 3.0 - 1.5);
      az += (_random.nextDouble() * 4.0 - 2.0);
    }

    // Gradual realistic battery drain (1% every ~200 iterations)
    if (_random.nextInt(200) == 0 && _batteryLevel > 5) {
      _batteryLevel--;
    }

    final data = BabySensorData(
      deviceId: 'DOODLEDRY-SIM-001',
      babyId: 'baby_leo_001',
      heartRate: double.parse(hr.toStringAsFixed(1)),
      spo2: double.parse(o2.toStringAsFixed(1)),
      temperature: double.parse(temp.toStringAsFixed(1)),
      ambientTemperature: double.parse(ambTemp.toStringAsFixed(1)),
      sensorModel: 'MLX90614',
      accelerationX: double.parse(ax.toStringAsFixed(2)),
      accelerationY: double.parse(ay.toStringAsFixed(2)),
      accelerationZ: double.parse(az.toStringAsFixed(2)),
      fallDetected: _forceFallDetected,
      activityStatus: _currentActivity,
      timestamp: DateTime.now(),
      batteryPercentage: _batteryLevel,
      isDeviceConnected: true,
      isSensorDataValid: true,
      isSimulation: true,
      heartRateState: SensorState.active,
      spo2State: SensorState.active,
      temperatureState: SensorState.active,
      motionState: SensorState.active,
      dataQuality: SensorDataQuality.valid,
    );

    _controller.add(data);
  }
}
