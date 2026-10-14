import 'package:doodledry/core/utils/sensor_data_validator.dart';
import 'package:doodledry/shared/models/baby_sensor_data.dart';
import 'package:doodledry/shared/models/sensor_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorDataValidator Tests', () {
    test('should validate normal physiological readings as valid quality', () {
      final data = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        heartRate: 125.0,
        spo2: 98.0,
        temperature: 36.8,
        accelerationX: 0.1,
        accelerationY: 0.0,
        accelerationZ: 9.81,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final validated = SensorDataValidator.validateAndSanitize(data);

      expect(validated.isSensorDataValid, isTrue);
      expect(validated.dataQuality, equals(SensorDataQuality.valid));
      expect(validated.heartRateState, equals(SensorState.active));
      expect(validated.spo2State, equals(SensorState.active));
      expect(validated.temperatureState, equals(SensorState.active));
    });

    test('should flag physiologically impossible heart rate as sensor error', () {
      final data = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        heartRate: 350.0, // Impossible BPM
        spo2: 98.0,
        temperature: 36.8,
        timestamp: DateTime.now(),
        isDeviceConnected: true,
      );

      final validated = SensorDataValidator.validateAndSanitize(data);

      expect(validated.heartRateState, equals(SensorState.error));
      expect(validated.heartRate, isNull);
      expect(validated.spo2, 98.0);
      expect(validated.dataQuality, equals(SensorDataQuality.sensorError));
      expect(validated.isSensorDataValid, isFalse);
    });

    test('should flag stale data when timestamp is older than threshold', () {
      final oldTimestamp = DateTime.now().subtract(const Duration(seconds: 25));
      final data = BabySensorData(
        deviceId: 'DOODLEDRY-001',
        babyId: 'baby_001',
        heartRate: 120.0,
        spo2: 98.0,
        temperature: 36.8,
        timestamp: oldTimestamp,
        isDeviceConnected: true,
      );

      final validated = SensorDataValidator.validateAndSanitize(data);

      expect(validated.dataQuality, equals(SensorDataQuality.stale));
      expect(validated.isSensorDataValid, isFalse);
    });
  });
}
