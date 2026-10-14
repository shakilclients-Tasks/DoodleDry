import 'dart:convert';
import 'dart:developer' as developer;
import '../../shared/models/baby_sensor_data.dart';
import '../../shared/models/sensor_status.dart';

/// Result returned from BLE packet parsing
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

  factory BleParseResult.success(BabySensorData data) {
    return BleParseResult(
      data: data,
      isSuccess: true,
      quality: data.dataQuality,
    );
  }

  factory BleParseResult.failure(String message, {SensorDataQuality quality = SensorDataQuality.invalid}) {
    return BleParseResult(
      data: null,
      isSuccess: false,
      errorMessage: message,
      quality: quality,
    );
  }
}

/// Robust parser for incoming BLE characteristic value bytes
class BlePacketParser {
  final List<int> _packetBuffer = [];
  DateTime? _lastTimestamp;

  /// Resets the internal accumulator buffer
  void resetBuffer() {
    _packetBuffer.clear();
    _lastTimestamp = null;
  }

  /// Parses a raw list of bytes from BLE notification
  BleParseResult parseBytes(List<int> rawBytes, {String defaultDeviceId = 'DOODLEDRY-001', String babyId = 'baby_default'}) {
    if (rawBytes.isEmpty) {
      return BleParseResult.failure("Empty byte payload received", quality: SensorDataQuality.missing);
    }

    try {
      // Legacy binary packets are exactly 12 bytes. Never guess binary from a
      // fragmented JSON chunk, which could turn arbitrary bytes into vitals.
      if (_packetBuffer.isEmpty && rawBytes.length == 12 && rawBytes.first != 123) {
        return _parseBinaryPacket(rawBytes, defaultDeviceId: defaultDeviceId, babyId: babyId);
      }
      if (_packetBuffer.isNotEmpty && rawBytes.length >= 11 &&
          utf8.decode(rawBytes.take(11).toList(), allowMalformed: true) == '{"deviceId"') {
        _packetBuffer.clear();
      }
      _packetBuffer.addAll(rawBytes);
      if (_packetBuffer.length > 1024) {
        _packetBuffer.clear();
        return BleParseResult.failure('Packet buffer overflow', quality: SensorDataQuality.invalid);
      }
      final packet = utf8.decode(_packetBuffer, allowMalformed: false).trim();
      if (packet.startsWith('{') && packet.endsWith('}')) {
        _packetBuffer.clear();
        return parseJsonString(packet, defaultDeviceId: defaultDeviceId, babyId: babyId);
      }
      return BleParseResult.failure('Incomplete packet', quality: SensorDataQuality.missing);
    } on FormatException {
      // A UTF-8 sequence may be split between notifications. Bound above still applies.
      return BleParseResult.failure('Incomplete UTF-8 packet', quality: SensorDataQuality.missing);
    } catch (e, stack) {
      developer.log("BLE Packet parse exception", error: e, stackTrace: stack, name: "BlePacketParser");
      return BleParseResult.failure("Decoding exception: $e", quality: SensorDataQuality.sensorError);
    }
  }

  /// Parses a JSON string representation into [BabySensorData]
  BleParseResult parseJsonString(String jsonStr, {String defaultDeviceId = 'DOODLEDRY-001', String babyId = 'baby_default'}) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return BleParseResult.failure("Root JSON is not a key-value object", quality: SensorDataQuality.invalid);
      }

      final data = BabySensorData.fromJson({
        ...decoded,
        'deviceId': decoded['deviceId'] ?? defaultDeviceId,
        'babyId': decoded['babyId'] ?? babyId,
      });

      // Validate timestamp monotonicity / duplicate checks
      if (_lastTimestamp != null && data.timestamp.isBefore(_lastTimestamp!)) {
        developer.log("Warning: Out-of-order timestamp detected: ${data.timestamp} vs previous $_lastTimestamp", name: "BlePacketParser");
      }
      _lastTimestamp = data.timestamp;

      return BleParseResult.success(data);
    } on FormatException catch (fe) {
      developer.log("Invalid JSON format: ${fe.message}", name: "BlePacketParser");
      return BleParseResult.failure("Invalid JSON syntax: ${fe.message}", quality: SensorDataQuality.invalid);
    } catch (e) {
      return BleParseResult.failure("JSON processing error: $e", quality: SensorDataQuality.invalid);
    }
  }

  /// Binary packet parser for raw microcontroller telemetry
  BleParseResult _parseBinaryPacket(List<int> bytes, {required String defaultDeviceId, required String babyId}) {
    try {
      // Byte structure:
      // [0]: Heart rate BPM (0..255)
      // [1]: SpO2 % (0..100)
      // [2..3]: Temperature in Celsius * 100 (Uint16)
      // [4..5]: Accel X in m/s^2 * 100 (Int16)
      // [6..7]: Accel Y in m/s^2 * 100 (Int16)
      // [8..9]: Accel Z in m/s^2 * 100 (Int16)
      // [10]: Flags: bit 0: Fall detected, bits 1..3: Activity (0: sleep, 1: awake, 2: active, 3: restless)
      // [11]: Battery % (0..100)

      final hr = bytes[0] > 0 ? bytes[0].toDouble() : null;
      final spo2 = (bytes[1] > 0 && bytes[1] <= 100) ? bytes[1].toDouble() : null;
      
      int rawTemp = (bytes[2] << 8) | bytes[3];
      final temp = rawTemp > 0 ? (rawTemp / 100.0) : null;

      int rawAx = (bytes[4] << 8) | bytes[5];
      if (rawAx > 32767) rawAx -= 65536;
      final ax = rawAx / 100.0;

      int rawAy = (bytes[6] << 8) | bytes[7];
      if (rawAy > 32767) rawAy -= 65536;
      final ay = rawAy / 100.0;

      int rawAz = (bytes[8] << 8) | bytes[9];
      if (rawAz > 32767) rawAz -= 65536;
      final az = rawAz / 100.0;

      final flags = bytes[10];
      final fallDetected = (flags & 0x01) != 0;
      final activityCode = (flags >> 1) & 0x07;
      String activity = 'sleeping';
      if (activityCode == 1) activity = 'awake';
      if (activityCode == 2) activity = 'active';
      if (activityCode == 3) activity = 'restless';

      final battery = bytes[11] <= 100 ? bytes[11] : null;

      final data = BabySensorData(
        deviceId: defaultDeviceId,
        babyId: babyId,
        heartRate: hr,
        spo2: spo2,
        temperature: temp,
        accelerationX: ax,
        accelerationY: ay,
        accelerationZ: az,
        fallDetected: fallDetected,
        activityStatus: activity,
        timestamp: DateTime.now(),
        batteryPercentage: battery,
        isDeviceConnected: true,
        isSensorDataValid: hr != null || spo2 != null || temp != null,
        dataQuality: SensorDataQuality.valid,
      );

      return BleParseResult.success(data);
    } catch (e) {
      return BleParseResult.failure("Failed to decode binary packet: $e", quality: SensorDataQuality.sensorError);
    }
  }
}
