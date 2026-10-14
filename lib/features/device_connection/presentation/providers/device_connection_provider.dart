import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/sensor_data_validator.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../alerts/presentation/providers/alert_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../simulation/data/simulation_engine.dart';
import '../../data/models/device_connection_state.dart';
import '../../data/models/discovered_device.dart';
import '../../data/repositories/ble_device_repository.dart';

final bleDeviceRepositoryProvider = Provider<BleDeviceRepository>((ref) {
  final repo = BleDeviceRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  final engine = SimulationEngine();
  engine.start();
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Live Stream of Discovered BLE Peripherals
final discoveredDevicesProvider =
    StreamProvider.autoDispose<List<DiscoveredBleDevice>>((ref) {
  final repo = ref.watch(bleDeviceRepositoryProvider);
  return repo.scanResultsStream;
});

/// Unified Device Connection State Provider
class DeviceConnectionNotifier extends StateNotifier<DeviceConnectionState> {
  final Ref _ref;
  StreamSubscription? _bleSub;

  DeviceConnectionNotifier(this._ref) : super(DeviceConnectionState.idle) {
    _init();
  }

  void _init() {
    final bleRepo = _ref.read(bleDeviceRepositoryProvider);
    _bleSub = bleRepo.connectionStateStream.listen((bleState) {
      if (!_ref.read(settingsProvider).isSimulationMode) {
        state = bleState;
      }
    });
    final isSim = _ref.read(settingsProvider).isSimulationMode;
    if (isSim) {
      state = DeviceConnectionState.receivingData;
    } else {
      state = bleRepo.currentState;
    }

    _ref.listen(settingsProvider.select((s) => s.isSimulationMode),
        (prev, isSim) {
      if (isSim) {
        state = DeviceConnectionState.receivingData;
      } else {
        final bleRepo = _ref.read(bleDeviceRepositoryProvider);
        state = bleRepo.currentState;
      }
    });
  }

  Future<void> startScan() async {
    final bleRepo = _ref.read(bleDeviceRepositoryProvider);
    await bleRepo.startScan();
  }

  Future<void> stopScan() async {
    final bleRepo = _ref.read(bleDeviceRepositoryProvider);
    await bleRepo.stopScan();
  }

  Future<bool> connect(String deviceId) async {
    final bleRepo = _ref.read(bleDeviceRepositoryProvider);
    final connected = await bleRepo.connectToDevice(deviceId);
    if (connected) {
      await _ref.read(settingsProvider.notifier).toggleSimulationMode(false);
    }
    return connected;
  }

  Future<void> disconnect() async {
    final isSim = _ref.read(settingsProvider).isSimulationMode;
    if (isSim) {
      _ref.read(simulationEngineProvider).toggleConnection(false);
      state = DeviceConnectionState.disconnected;
    } else {
      final bleRepo = _ref.read(bleDeviceRepositoryProvider);
      await bleRepo.disconnect();
      state = DeviceConnectionState.disconnected;
    }
  }

  Future<void> reconnect() async {
    final isSim = _ref.read(settingsProvider).isSimulationMode;
    if (isSim) {
      _ref.read(simulationEngineProvider).toggleConnection(true);
      state = DeviceConnectionState.receivingData;
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }
}

final deviceConnectionNotifierProvider =
    StateNotifierProvider<DeviceConnectionNotifier, DeviceConnectionState>(
        (ref) {
  return DeviceConnectionNotifier(ref);
});

/// Unified Live Sensor Data Stream Provider (Active routing between Hardware BLE and Simulator)
final activeSensorDataProvider = StreamProvider<BabySensorData>((ref) {
  final isSim = ref.watch(settingsProvider.select((s) => s.isSimulationMode));
  final alertRepo = ref.watch(alertRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final thresholds = ref.watch(settingsProvider.select((s) => s.thresholds));

  Stream<BabySensorData> sourceStream;
  if (isSim) {
    sourceStream = ref.watch(simulationEngineProvider).sensorDataStream;
  } else {
    sourceStream = ref.watch(bleDeviceRepositoryProvider).sensorDataStream;
  }

  final controller = StreamController<BabySensorData>();
  BabySensorData? latest;
  bool updatingSent = false;
  bool expiredSent = false;
  final subscription = sourceStream.listen((data) {
    latest = data;
    updatingSent = false;
    expiredSent = false;
    if (data.isDeviceConnected &&
        !data.isStale(maxAge: SensorDataValidator.staleDataThreshold)) {
      alertRepo.evaluateVitals(data, thresholds);
      historyRepo.recordDataPoint(data);
    }
    controller.add(data);
  }, onError: controller.addError);
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    final data = latest;
    if (data == null || !data.isDeviceConnected) return;
    final age = DateTime.now().difference(data.timestamp);
    if (age > SensorDataValidator.staleDataThreshold && !expiredSent) {
      expiredSent = true;
      controller.add(BabySensorData.disconnected(
              deviceId: data.deviceId, babyId: data.babyId)
          .copyWith(
              timestamp: data.timestamp, dataQuality: SensorDataQuality.stale));
    } else if (age > const Duration(seconds: 3) && !updatingSent) {
      updatingSent = true;
      controller.add(data.copyWith(
        heartRate: null,
        spo2: null,
        temperature: null,
        isSensorDataValid: false,
        heartRateState: SensorState.measuring,
        spo2State: SensorState.measuring,
        temperatureState: SensorState.measuring,
        motionState: SensorState.noData,
        dataQuality: SensorDataQuality.stale,
      ));
    }
  });
  ref.onDispose(() {
    timer.cancel();
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});
