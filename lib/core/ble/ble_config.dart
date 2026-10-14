/// Centralized Bluetooth Low Energy (BLE) Configuration for DOODLEDRY.
/// 
/// UUIDs shared with firmware/esp32_doodledry/esp32_doodledry.ino.
class BleConfig {
  /// DOODLEDRY Primary Sensor GATT Service UUID
  /// Default prototype UUID (128-bit custom service)
  static const String serviceUuid = "0000fff0-0000-1000-8000-00805f9b34fb";

  /// Real-time sensor telemetry characteristic UUID (Notify / Read)
  /// Streams JSON or structured binary packets containing HR, SpO2, Temp, Accel, Fall, Battery
  static const String sensorCharacteristicUuid = "0000fff1-0000-1000-8000-00805f9b34fb";

  /// Device Control & Configuration characteristic UUID (Write / Write without response)
  static const String commandCharacteristicUuid = "0000fff2-0000-1000-8000-00805f9b34fb";

  /// Device Information Service (Standard SIG Service)
  static const String deviceInformationServiceUuid = "0000180a-0000-1000-8000-00805f9b34fb";
  static const String batteryServiceUuid = "0000180f-0000-1000-8000-00805f9b34fb";

  /// Advertised Device Name Prefix filter
  static const String deviceNamePrefix = "DOODLEDRY";

  /// Timeout durations
  static const Duration scanTimeout = Duration(seconds: 12);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration autoReconnectInterval = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;

  /// MTU Request Size
  static const int targetMtu = 512;
}
