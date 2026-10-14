/// Model representing a discovered BLE peripheral
class DiscoveredBleDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isConnectable;
  final DateTime lastSeen;

  const DiscoveredBleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnectable = true,
    required this.lastSeen,
  });

  /// Signal strength rating (1..4 bars)
  int get signalBars {
    if (rssi >= -60) return 4;
    if (rssi >= -75) return 3;
    if (rssi >= -90) return 2;
    return 1;
  }
}
