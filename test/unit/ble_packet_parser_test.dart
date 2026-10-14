import 'dart:convert';
import 'package:doodledry/core/ble/ble_packet_parser.dart';
import 'package:doodledry/shared/models/sensor_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlePacketParser Tests', () {
    late BlePacketParser parser;

    setUp(() {
      parser = BlePacketParser();
    });

    test('should successfully parse valid JSON BLE sensor packet', () {
      final jsonPayload = jsonEncode({
        "deviceId": "DOODLEDRY-001",
        "heartRate": 128.5,
        "spo2": 98.0,
        "temperature": 36.8,
        "ax": 0.12,
        "ay": -0.03,
        "az": 9.81,
        "fallDetected": false,
        "activityStatus": "sleeping",
        "battery": 85,
        "timestamp": "2026-08-27T10:30:00.000Z"
      });

      final bytes = utf8.encode(jsonPayload);
      final result = parser.parseBytes(bytes);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.deviceId, equals('DOODLEDRY-001'));
      expect(result.data!.heartRate, equals(128.5));
      expect(result.data!.spo2, equals(98.0));
      expect(result.data!.temperature, equals(36.8));
      expect(result.data!.fallDetected, isFalse);
      expect(result.data!.activityStatus, equals('sleeping'));
      expect(result.data!.batteryPercentage, equals(85));
    });

    test('should handle missing and null sensor values gracefully without throwing', () {
      final jsonPayload = jsonEncode({
        "deviceId": "DOODLEDRY-002",
        "heartRate": null,
        "spo2": null,
        "temperature": 37.0,
      });

      final bytes = utf8.encode(jsonPayload);
      final result = parser.parseBytes(bytes);

      expect(result.isSuccess, isTrue);
      expect(result.data!.heartRate, isNull);
      expect(result.data!.spo2, isNull);
      expect(result.data!.temperature, equals(37.0));
      expect(result.data!.heartRateState, equals(SensorState.noData));
    });

    test('should return failure for corrupted JSON syntax without crashing', () {
      const corruptedJson = '{"deviceId": "DOODLEDRY-001", "heartRate": 128,'; // Missing closing bracket
      final bytes = utf8.encode(corruptedJson);

      final result = parser.parseBytes(bytes);
      expect(result.isSuccess, isFalse);
    });

    test('should parse raw 12-byte binary BLE struct fallback', () {
      // Byte layout: [HR, SpO2, TempHi, TempLo, AxHi, AxLo, AyHi, AyLo, AzHi, AzLo, Flags, Batt]
      // Temp = 36.80 * 100 = 3680 = 0x0E60 -> [0x0E, 0x60]
      // Accel Z = 9.81 * 100 = 981 = 0x03D5 -> [0x03, 0xD5]
      final rawBytes = [
        130, // HR 130 BPM
        99,  // SpO2 99%
        0x0E, 0x60, // Temp 36.80 C
        0x00, 0x0C, // Ax 0.12
        0xFF, 0xFE, // Ay -0.02
        0x03, 0xD5, // Az 9.81
        0x00, // Flags (no fall, sleep)
        90,   // Battery 90%
      ];

      final result = parser.parseBytes(rawBytes);
      expect(result.isSuccess, isTrue);
      expect(result.data!.heartRate, equals(130.0));
      expect(result.data!.spo2, equals(99.0));
      expect(result.data!.temperature, closeTo(36.80, 0.01));
      expect(result.data!.batteryPercentage, equals(90));
    });

    test('reassembles MTU-23 chunks and respects per-sensor validity', () {
      final packet = utf8.encode(jsonEncode({
        'deviceId': 'DOODLEDRY-001',
        'heartRate': null, 'spo2': null, 'temperature': 36.7,
        'activity': 'moving', 'fingerDetected': false,
        'heartRateValid': false, 'spo2Valid': false,
        'temperatureValid': true, 'motionValid': true,
        'battery': null,
      }));
      BleParseResult? result;
      for (var start = 0; start < packet.length; start += 20) {
        final end = (start + 20).clamp(0, packet.length);
        result = parser.parseBytes(packet.sublist(start, end));
      }
      expect(result!.isSuccess, isTrue);
      expect(result.data!.heartRate, isNull);
      expect(result.data!.heartRateState, SensorState.noData);
      expect(result.data!.temperature, 36.7);
      expect(result.data!.activityStatus, 'moving');
      expect(result.data!.batteryPercentage, isNull);
    });

    test('invalid flags cannot turn a numeric field into a live reading', () {
      final result = parser.parseJsonString(jsonEncode({
        'heartRate': 80, 'spo2': 98, 'temperature': 36.8,
        'fingerDetected': false, 'heartRateValid': false,
        'spo2Valid': false, 'temperatureValid': false,
      }));
      expect(result.data!.heartRate, isNull);
      expect(result.data!.spo2, isNull);
      expect(result.data!.temperature, isNull);
    });
  });
}
