import 'dart:convert';

import 'package:doodledry/core/ble/ble_packet_parser.dart';
import 'package:doodledry/shared/models/sensor_status.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> hardwarePacket({
  double? heartRate = 128,
  double? spo2 = 98,
  double? temperature = 36.8,
  bool fingerDetected = true,
}) =>
    {
      'protocol': 2,
      'deviceId': 'DOODLEDRY-001',
      'sensorModel': 'MLX90614_IR_OBJECT',
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'ambientTemp': 25.1,
      'activity': 'still',
      'fingerDetected': fingerDetected,
      'heartRateValid': heartRate != null,
      'spo2Valid': spo2 != null,
      'temperatureValid': temperature != null,
      'temperatureMeasuring': false,
      'motionValid': true,
      'poorSignal': false,
      'fallDetected': false,
      'battery': null,
    };

void main() {
  group('BLE hardware packet parser', () {
    late BlePacketParser parser;

    setUp(() => parser = BlePacketParser());

    test('reassembles 20-byte notifications from current ESP32 firmware', () {
      final bytes = utf8.encode(jsonEncode(hardwarePacket()));
      BleParseResult? result;
      for (var start = 0; start < bytes.length; start += 20) {
        result = parser.parseBytes(
            bytes.sublist(start, (start + 20).clamp(0, bytes.length)));
      }
      expect(result!.isSuccess, isTrue);
      expect(result.data!.heartRate, 128);
      expect(result.data!.spo2, 98);
      expect(result.data!.temperature, 36.8);
      expect(result.data!.sensorModel, 'MLX90614_IR_OBJECT');
    });

    test('missing sensor values stay null rather than becoming defaults', () {
      final packet = hardwarePacket(
          heartRate: null,
          spo2: null,
          temperature: null,
          fingerDetected: false);
      final result = parser.parseJsonString(jsonEncode(packet));
      expect(result.isSuccess, isTrue);
      expect(result.data!.heartRate, isNull);
      expect(result.data!.spo2, isNull);
      expect(result.data!.temperature, isNull);
      expect(result.data!.heartRateState, SensorState.noData);
    });

    test('rejects arbitrary binary bytes that could appear to be vitals', () {
      final result = parser
          .parseBytes([130, 99, 0x0e, 0x60, 0, 12, 0xff, 0xfe, 3, 0xd5, 0, 90]);
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
    });

    test('rejects old firmware and packets without validity flags', () {
      final old = hardwarePacket()..remove('protocol');
      expect(parser.parseJsonString(jsonEncode(old)).isSuccess, isFalse);
      final missingFlag = hardwarePacket()..remove('spo2Valid');
      expect(
          parser.parseJsonString(jsonEncode(missingFlag)).isSuccess, isFalse);
    });

    test('rejects contradictory validity and missing contact', () {
      final contradictory = hardwarePacket()..['spo2Valid'] = false;
      expect(
          parser.parseJsonString(jsonEncode(contradictory)).isSuccess, isFalse);
      final noContact = hardwarePacket()..['fingerDetected'] = false;
      expect(parser.parseJsonString(jsonEncode(noContact)).isSuccess, isFalse);
    });

    test('starts a new frame after a lost notification', () {
      parser.parseBytes(utf8.encode('{"protocol":2,"deviceId":'));
      final bytes = utf8.encode(jsonEncode(hardwarePacket()));
      BleParseResult? result;
      for (var start = 0; start < bytes.length; start += 20) {
        result = parser.parseBytes(
            bytes.sublist(start, (start + 20).clamp(0, bytes.length)));
      }
      expect(result!.isSuccess, isTrue);
      expect(result.data!.heartRate, 128);
    });
  });
}
