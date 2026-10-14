import 'dart:convert';

import '../../shared/models/baby_sensor_data.dart';
import '../../shared/models/sensor_status.dart';

class BleParseResult {
  final BabySensorData? data;
  final bool isSuccess;
  final String? errorMessage;
  final SensorDataQuality quality;

  const BleParseResult({
    this.data,
    required this.isSuccess,
    this.errorMessage,
    this.quality = SensorDataQuality.valid,
  });

  factory BleParseResult.success(BabySensorData data) =>
      BleParseResult(data: data, isSuccess: true, quality: data.dataQuality);

  factory BleParseResult.failure(String message,
          {SensorDataQuality quality = SensorDataQuality.invalid}) =>
      BleParseResult(isSuccess: false, errorMessage: message, quality: quality);
}

/// Accepts only the versioned JSON sent by the physical ESP32 firmware.
/// Arbitrary 12-byte fragments must never be interpreted as vital readings.
class BlePacketParser {
  static const int protocolVersion = 2;
  static const int _maximumPacketBytes = 1024;
  static final List<int> _framePrefix = utf8.encode('{"protocol":');
  final List<int> _packetBuffer = [];

  void resetBuffer() => _packetBuffer.clear();

  BleParseResult parseBytes(List<int> rawBytes,
      {String defaultDeviceId = 'DOODLEDRY-001',
      String babyId = 'baby_default'}) {
    if (rawBytes.isEmpty) {
      return BleParseResult.failure('Empty BLE notification',
          quality: SensorDataQuality.missing);
    }
    if (_packetBuffer.isNotEmpty && _startsWith(rawBytes, _framePrefix)) {
      // A new frame started after a dropped chunk. Discard the incomplete one.
      _packetBuffer.clear();
    }
    if (_packetBuffer.isEmpty && rawBytes.first != 0x7b) {
      return BleParseResult.failure('Unexpected BLE frame; JSON required');
    }
    _packetBuffer.addAll(rawBytes);
    if (_packetBuffer.length > _maximumPacketBytes) {
      _packetBuffer.clear();
      return BleParseResult.failure('BLE packet exceeded maximum length');
    }
    try {
      final packet = utf8.decode(_packetBuffer).trim();
      if (!packet.endsWith('}')) {
        return BleParseResult.failure('Incomplete JSON frame',
            quality: SensorDataQuality.missing);
      }
      _packetBuffer.clear();
      return parseJsonString(packet, babyId: babyId);
    } on FormatException {
      return BleParseResult.failure('Incomplete or invalid UTF-8 frame',
          quality: SensorDataQuality.missing);
    }
  }

  BleParseResult parseJsonString(String jsonStr,
      {String defaultDeviceId = 'DOODLEDRY-001',
      String babyId = 'baby_default'}) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return BleParseResult.failure('BLE packet is not a JSON object');
      }
      if (decoded['protocol'] != protocolVersion ||
          decoded['deviceId'] is! String ||
          !(decoded['deviceId'] as String).startsWith('DOODLEDRY') ||
          decoded['sensorModel'] != 'MLX90614_IR_OBJECT') {
        return BleParseResult.failure('Unsupported ESP32 telemetry protocol');
      }
      for (final key in [
        'fingerDetected',
        'heartRateValid',
        'spo2Valid',
        'temperatureValid',
        'motionValid',
        'poorSignal',
      ]) {
        if (decoded[key] is! bool) {
          return BleParseResult.failure('Missing hardware validity flag: $key');
        }
      }
      for (final pair in [
        ('heartRate', 'heartRateValid'),
        ('spo2', 'spo2Valid'),
        ('temperature', 'temperatureValid'),
      ]) {
        final reading = decoded[pair.$1];
        final valid = decoded[pair.$2] as bool;
        if (valid != (reading is num && reading.isFinite)) {
          return BleParseResult.failure(
              'Inconsistent hardware reading: ${pair.$1}');
        }
      }
      if (decoded['fingerDetected'] == false &&
          (decoded['heartRateValid'] == true || decoded['spo2Valid'] == true)) {
        return BleParseResult.failure('Optical reading without sensor contact');
      }
      final data = BabySensorData.fromJson({
        ...decoded,
        'babyId': babyId,
      });
      return BleParseResult.success(data);
    } on FormatException catch (e) {
      return BleParseResult.failure('Invalid JSON: ${e.message}');
    } catch (e) {
      return BleParseResult.failure('Invalid BLE packet: $e');
    }
  }

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}
