/// Comprehensive Device Connection State Machine states for DOODLEDRY hardware
enum DeviceConnectionState {
  idle,
  scanning,
  deviceFound,
  connecting,
  connected,
  discoveringServices,
  subscribing,
  receivingData,
  reconnecting,
  disconnected,
  connectionFailed,
  bluetoothDisabled,
  permissionDenied;

  String get displayName {
    switch (this) {
      case DeviceConnectionState.idle:
        return 'Ready to Connect';
      case DeviceConnectionState.scanning:
        return 'Scanning for Wearable...';
      case DeviceConnectionState.deviceFound:
        return 'Device Found';
      case DeviceConnectionState.connecting:
        return 'Connecting...';
      case DeviceConnectionState.connected:
        return 'Hardware Connected';
      case DeviceConnectionState.discoveringServices:
        return 'Discovering GATT Services...';
      case DeviceConnectionState.subscribing:
        return 'Subscribing to Sensors...';
      case DeviceConnectionState.receivingData:
        return 'Live Data Streaming';
      case DeviceConnectionState.reconnecting:
        return 'Reconnecting...';
      case DeviceConnectionState.disconnected:
        return 'Device Disconnected';
      case DeviceConnectionState.connectionFailed:
        return 'Connection Failed';
      case DeviceConnectionState.bluetoothDisabled:
        return 'Bluetooth is Turned Off';
      case DeviceConnectionState.permissionDenied:
        return 'Bluetooth Permission Required';
    }
  }

  bool get isConnectedOrReceiving =>
      this == DeviceConnectionState.connected ||
      this == DeviceConnectionState.discoveringServices ||
      this == DeviceConnectionState.subscribing ||
      this == DeviceConnectionState.receivingData;

  bool get isConnectingOrScanning =>
      this == DeviceConnectionState.scanning ||
      this == DeviceConnectionState.deviceFound ||
      this == DeviceConnectionState.connecting ||
      this == DeviceConnectionState.discoveringServices ||
      this == DeviceConnectionState.subscribing ||
      this == DeviceConnectionState.reconnecting;
}
