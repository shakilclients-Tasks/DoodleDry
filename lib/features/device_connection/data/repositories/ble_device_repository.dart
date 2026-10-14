import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/ble/ble_config.dart';
import '../../../../core/ble/ble_packet_parser.dart';
import '../../../../core/utils/sensor_data_validator.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../models/device_connection_state.dart';
import '../models/discovered_device.dart';

abstract class IDeviceRepository {
  Stream<DeviceConnectionState> get connectionStateStream;
  Stream<BabySensorData> get sensorDataStream;
  Stream<List<DiscoveredBleDevice>> get scanResultsStream;
  DeviceConnectionState get currentState;
  String? get connectedDeviceId;

  Future<bool> checkBluetoothAvailable();
  Future<void> startScan({Duration? timeout});
  Future<void> stopScan();
  Future<bool> connectToDevice(String deviceId,
      {String babyId = 'baby_default'});
  Future<void> disconnect();
  void dispose();
}

/// Production Bluetooth Low Energy Repository implementation for DOODLEDRY wearable
class BleDeviceRepository implements IDeviceRepository {
  final BlePacketParser _parser = BlePacketParser();

  final StreamController<DeviceConnectionState> _connectionStateController =
      StreamController<DeviceConnectionState>.broadcast();
  final StreamController<BabySensorData> _sensorDataController =
      StreamController<BabySensorData>.broadcast();
  final StreamController<List<DiscoveredBleDevice>> _scanResultsController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();

  DeviceConnectionState _currentState = DeviceConnectionState.idle;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _sensorCharacteristic;
  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;

  final Map<String, DiscoveredBleDevice> _discoveredDevices = {};
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _currentBabyId;
  bool _manualDisconnect = false;
  bool _connecting = false;
  int packetCount = 0;
  int malformedPacketCount = 0;
  String? lastBleError;
  DateTime? lastPacketAt;
  String? get deviceName => _connectedDevice?.platformName;
  int? get rssi => _discoveredDevices[_connectedDevice?.remoteId.str]?.rssi;

  BleDeviceRepository() {
    _initBluetoothListener();
  }

  @override
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<BabySensorData> get sensorDataStream => _sensorDataController.stream;

  @override
  Stream<List<DiscoveredBleDevice>> get scanResultsStream =>
      _scanResultsController.stream;

  @override
  DeviceConnectionState get currentState => _currentState;

  @override
  String? get connectedDeviceId => _connectedDevice?.remoteId.str;

  void _updateState(DeviceConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
    developer.log("BLE Connection State: ${state.name}",
        name: "BleDeviceRepository");
  }

  void _initBluetoothListener() {
    try {
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
        (BluetoothAdapterState state) {
          if (state == BluetoothAdapterState.unauthorized) {
            _updateState(DeviceConnectionState.permissionDenied);
          } else if (state == BluetoothAdapterState.off) {
            _updateState(DeviceConnectionState.bluetoothDisabled);
            _sensorDataController
                .add(BabySensorData.disconnected(deviceId: connectedDeviceId));
          } else if (state == BluetoothAdapterState.on &&
              (_currentState == DeviceConnectionState.bluetoothDisabled ||
                  _currentState == DeviceConnectionState.permissionDenied)) {
            _updateState(DeviceConnectionState.idle);
          }
        },
        onError: (e) {
          developer.log("Bluetooth adapterState error: $e",
              name: "BleDeviceRepository");
        },
      );
    } catch (e) {
      developer.log(
          "Bluetooth listener unsupported on current host platform: $e",
          name: "BleDeviceRepository");
    }
  }

  @override
  Future<bool> checkBluetoothAvailable() async {
    try {
      final isAvailable = await FlutterBluePlus.isSupported;
      if (!isAvailable) {
        _updateState(DeviceConnectionState.bluetoothDisabled);
        return false;
      }
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.unauthorized) {
        _updateState(DeviceConnectionState.permissionDenied);
        return false;
      }
      if (state != BluetoothAdapterState.on) {
        _updateState(DeviceConnectionState.bluetoothDisabled);
        return false;
      }
      return true;
    } catch (e) {
      developer.log("Error checking Bluetooth: $e",
          name: "BleDeviceRepository");
      lastBleError = e.toString();
      _updateState(e.toString().toLowerCase().contains('permission')
          ? DeviceConnectionState.permissionDenied
          : DeviceConnectionState.connectionFailed);
      return false;
    }
  }

  @override
  Future<void> startScan({Duration? timeout}) async {
    if (_currentState == DeviceConnectionState.scanning ||
        _currentState.isConnectedOrReceiving ||
        _connecting) {
      return;
    }
    final hasBt = await checkBluetoothAvailable();
    if (!hasBt) return;

    lastBleError = null;
    _discoveredDevices.clear();
    _scanResultsController.add([]);
    _updateState(DeviceConnectionState.scanning);

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;

        final id = result.device.remoteId.str;
        final isCandidate =
            name.toUpperCase().startsWith(BleConfig.deviceNamePrefix) ||
                result.advertisementData.serviceUuids
                    .contains(Guid(BleConfig.serviceUuid));

        if (isCandidate && result.advertisementData.connectable) {
          _discoveredDevices[id] = DiscoveredBleDevice(
            id: id,
            name: name.isNotEmpty ? name : 'Wearable ($id)',
            rssi: result.rssi,
            isConnectable: result.advertisementData.connectable,
            lastSeen: DateTime.now(),
          );
        }
      }
      _scanResultsController.add(_discoveredDevices.values.toList());
    }, onError: (Object e) {
      lastBleError = e.toString();
      _updateState(DeviceConnectionState.connectionFailed);
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout ?? BleConfig.scanTimeout,
      );
      // startScan returns when scanning starts, not when its timeout expires.
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
      if (_currentState == DeviceConnectionState.scanning) {
        _updateState(DeviceConnectionState.idle);
      }
    } catch (e) {
      developer.log("Scan error: $e", name: "BleDeviceRepository");
      lastBleError = e.toString();
      _updateState(e.toString().toLowerCase().contains('permission')
          ? DeviceConnectionState.permissionDenied
          : DeviceConnectionState.connectionFailed);
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      lastBleError = e.toString();
    }
    if (_currentState == DeviceConnectionState.scanning) {
      _updateState(DeviceConnectionState.idle);
    }
  }

  @override
  Future<bool> connectToDevice(String deviceId,
      {String babyId = 'baby_default'}) async {
    if (_connecting) return false;
    _connecting = true;
    _currentBabyId = babyId;
    _manualDisconnect = false;

    try {
      await stopScan();
      lastBleError = null;
      _updateState(DeviceConnectionState.connecting);
      final device = BluetoothDevice.fromId(deviceId);
      _connectedDevice = device;

      // Listen for unexpected connection state changes
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            !_manualDisconnect &&
            _currentState.isConnectedOrReceiving) {
          _handleUnexpectedDisconnection();
        }
      });

      await device.connect(
        timeout: BleConfig.connectionTimeout,
        autoConnect: false,
        mtu:
            null, // The firmware uses 20-byte notifications; no negotiation is required.
      );

      _updateState(DeviceConnectionState.connected);

      // Discover GATT Services
      _updateState(DeviceConnectionState.discoveringServices);
      final services = await device.discoverServices();

      // Find sensor characteristic
      BluetoothCharacteristic? sensorChar;
      for (final service in services) {
        if (service.uuid != Guid(BleConfig.serviceUuid)) continue;
        for (final char in service.characteristics) {
          if (char.uuid == Guid(BleConfig.sensorCharacteristicUuid) &&
              char.properties.notify) {
            sensorChar = char;
            break;
          }
        }
        if (sensorChar != null) break;
      }

      if (sensorChar == null) {
        throw StateError(
            'DOODLEDRY telemetry characteristic not found. Check the ESP32 firmware.');
      }

      _sensorCharacteristic = sensorChar;
      _updateState(DeviceConnectionState.subscribing);

      // Subscribe to Notifications
      _parser.resetBuffer();

      _characteristicSubscription?.cancel();
      _characteristicSubscription = sensorChar.onValueReceived.listen((bytes) {
        final parseResult = _parser.parseBytes(
          bytes,
          defaultDeviceId: device.platformName.isNotEmpty
              ? device.platformName
              : device.remoteId.str,
          babyId: _currentBabyId ?? 'baby_default',
        );

        if (parseResult.isSuccess && parseResult.data != null) {
          final validatedData =
              SensorDataValidator.validateAndSanitize(parseResult.data!);
          packetCount++;
          lastPacketAt = validatedData.timestamp;
          _reconnectAttempts = 0;
          _sensorDataController.add(validatedData);
          if (_currentState != DeviceConnectionState.receivingData) {
            _updateState(DeviceConnectionState.receivingData);
          }
        } else if (parseResult.quality != SensorDataQuality.missing) {
          malformedPacketCount++;
          lastBleError = parseResult.errorMessage;
        }
      });

      await sensorChar.setNotifyValue(true);
      return true;
    } catch (e) {
      developer.log("Connection failed: $e", name: "BleDeviceRepository");
      lastBleError = e.toString();
      await _characteristicSubscription?.cancel();
      _characteristicSubscription = null;
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      try {
        await _connectedDevice?.disconnect();
      } catch (_) {}
      _sensorCharacteristic = null;
      _sensorDataController
          .add(BabySensorData.disconnected(deviceId: deviceId));
      if (e.toString().toLowerCase().contains('permission')) {
        _updateState(DeviceConnectionState.permissionDenied);
      } else if (e is StateError) {
        _updateState(DeviceConnectionState.connectionFailed);
      } else {
        _scheduleReconnect();
      }
      return false;
    } finally {
      _connecting = false;
    }
  }

  void _handleUnexpectedDisconnection() {
    developer.log("Device disconnected unexpectedly",
        name: "BleDeviceRepository");
    _sensorDataController.add(BabySensorData.disconnected(
      deviceId: _connectedDevice?.remoteId.str,
      babyId: _currentBabyId,
    ));

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;
    if (_reconnectTimer?.isActive == true) return;
    if (_reconnectAttempts < BleConfig.maxReconnectAttempts) {
      _reconnectAttempts++;
      _updateState(DeviceConnectionState.reconnecting);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(BleConfig.autoReconnectInterval, () {
        if (_connectedDevice != null) {
          connectToDevice(_connectedDevice!.remoteId.str,
              babyId: _currentBabyId ?? 'baby_default');
        }
      });
    } else {
      _updateState(DeviceConnectionState.connectionFailed);
    }
  }

  @override
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts =
        BleConfig.maxReconnectAttempts; // prevent auto-reconnect
    await _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _sensorCharacteristic?.setNotifyValue(false);
        await _connectedDevice?.disconnect();
      } catch (_) {}
      _connectedDevice = null;
      _sensorCharacteristic = null;
    }

    _updateState(DeviceConnectionState.disconnected);
    _sensorDataController.add(BabySensorData.disconnected());
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _connectionStateController.close();
    _sensorDataController.close();
    _scanResultsController.close();
  }
}
