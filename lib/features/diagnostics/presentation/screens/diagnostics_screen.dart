import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../device_connection/data/models/device_connection_state.dart';
import '../../../device_connection/presentation/providers/device_connection_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorDataAsync = ref.watch(activeSensorDataProvider);
    final connectionState = ref.watch(deviceConnectionNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final ble = ref.watch(bleDeviceRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sensorData = sensorDataAsync.value ?? BabySensorData.disconnected();
    final isConnected = sensorData.isDeviceConnected && connectionState.isConnectedOrReceiving;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'System Diagnostics',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HARDWARE & SUBSYSTEM HEALTH',
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              CustomCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  children: [
                    // 1. Bluetooth Status
                    _buildDiagnosticRow(
                      title: 'Bluetooth Adapter',
                      status: connectionState == DeviceConnectionState.bluetoothDisabled
                          ? 'Bluetooth OFF' : connectionState == DeviceConnectionState.permissionDenied
                              ? 'Permission denied' : connectionState.displayName,
                      isHealthy: isConnected,
                      icon: Icons.bluetooth_rounded,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),

                    // 2. Wearable Device Status
                    _buildDiagnosticRow(
                      title: 'Wearable Device (${sensorData.deviceId})',
                      status: isConnected ? 'Connected & Active' : 'Disconnected / Searching',
                      isHealthy: isConnected,
                      icon: Icons.watch_rounded,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),

                    // 3. Heart Rate Sensor
                    _buildDiagnosticRow(
                      title: 'Heart Rate Optical Sensor',
                      status: isConnected ? '${sensorData.heartRateState.displayName}; finger ${sensorData.fingerDetected == true ? 'detected' : 'not detected'}' : 'Disconnected',
                      isHealthy: isConnected && sensorData.heartRateState == SensorState.active,
                      icon: Icons.favorite_rounded,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),

                    // 4. SpO2 Sensor
                    _buildDiagnosticRow(
                      title: 'SpO₂ Pulse Oximeter Sensor',
                      status: isConnected ? sensorData.spo2State.displayName : 'Disconnected',
                      isHealthy: isConnected && sensorData.spo2State == SensorState.active,
                      icon: Icons.air_rounded,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),

                    // 5. Temperature Sensor
                    _buildDiagnosticRow(
                      title: 'MLX90614 Object Temperature',
                      status: isConnected ? sensorData.temperatureState.displayName : 'Disconnected',
                      isHealthy: isConnected && sensorData.temperatureState == SensorState.active,
                      icon: Icons.thermostat_rounded,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),

                    // 6. Motion / Accelerometer Sensor
                    _buildDiagnosticRow(
                      title: '3-Axis Motion / IMU Sensor',
                      status: isConnected && sensorData.motionState == SensorState.active
                          ? (sensorData.fallDetected == true
                              ? '⚠ FALL DETECTED! (${sensorData.formattedActivity})'
                              : 'Accelerometer and gyroscope: ${sensorData.formattedActivity}')
                          : sensorData.motionState.displayName,
                      isHealthy: isConnected && sensorData.motionState == SensorState.active && sensorData.fallDetected != true,
                      icon: Icons.directions_run_rounded,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),

                    // 7. Cloud Sync Status
                    _buildDiagnosticRow(
                      title: 'Cloud Database Sync',
                      status: settings.cloudSyncEnabled ? 'Synced' : 'Offline Mode',
                      isHealthy: settings.cloudSyncEnabled,
                      icon: Icons.cloud_done_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Telemetry Info Card
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAST DATA PACKET RECEIVED',
                          style: AppTextStyles.label.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ble.lastPacketAt == null ? 'Never' : AppDateFormatter.formatTime(ble.lastPacketAt!),
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sensorData.dataQuality == SensorDataQuality.valid
                            ? AppColors.successBg
                            : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sensorData.dataQuality.displayName,
                        style: AppTextStyles.label.copyWith(
                          color: sensorData.dataQuality == SensorDataQuality.valid
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BLE DETAILS', style: AppTextStyles.titleSmall),
                  Text('State: ${connectionState.displayName}'),
                  Text('Device: ${ble.deviceName?.isNotEmpty == true ? ble.deviceName : '--'}'),
                  Text('ID: ${ble.connectedDeviceId ?? '--'}'),
                  Text('RSSI: ${ble.rssi?.toString() ?? '--'} dBm'),
                  Text('Packets: ${ble.packetCount}'),
                  Text('Malformed: ${ble.malformedPacketCount}'),
                  Text('Last BLE error: ${ble.lastBleError ?? '--'}'),
                  Text('MAX30102 finger: ${sensorData.fingerDetected?.toString() ?? '--'}'),
                  Text('Heart rate valid: ${sensorData.heartRateState == SensorState.active}'),
                  Text('SpO₂ valid: ${sensorData.spo2State == SensorState.active}'),
                  Text('MLX90614 valid: ${sensorData.temperatureState == SensorState.active}'),
                  Text('MPU6050 accelerometer valid: ${sensorData.motionState == SensorState.active}'),
                  Text('MPU6050 gyroscope valid: ${sensorData.motionState == SensorState.active}'),
                  if (kDebugMode && sensorData.diagnostics != null) ...[
                    const Divider(),
                    Text('CALIBRATION DATA (DEVELOPMENT)', style: AppTextStyles.titleSmall),
                    Text('Raw RED: ${sensorData.diagnostics!['red']}'),
                    Text('Raw IR: ${sensorData.diagnostics!['ir']}'),
                    Text('Finger detected: ${sensorData.fingerDetected}'),
                    Text('Calculated BPM: ${sensorData.heartRate?.toStringAsFixed(0) ?? '--'}'),
                    Text('Calculated SpO₂: ${sensorData.spo2?.toStringAsFixed(1) ?? '--'}'),
                    Text('Signal quality (AC/DC): ${sensorData.diagnostics!['q']}'),
                    Text('Ambient temperature: ${sensorData.diagnostics!['ambient']} °C'),
                    Text('Object temperature: ${sensorData.diagnostics!['object']} °C'),
                    Text('Final temperature: ${sensorData.temperature?.toStringAsFixed(2) ?? '--'} °C'),
                    Text('Calibration offset: ${sensorData.diagnostics!['offset']} °C'),
                    Text('ax: ${sensorData.diagnostics!['ax']}  ay: ${sensorData.diagnostics!['ay']}  az: ${sensorData.diagnostics!['az']}'),
                    Text('gx: ${sensorData.diagnostics!['gx']}  gy: ${sensorData.diagnostics!['gy']}  gz: ${sensorData.diagnostics!['gz']}'),
                    Text('Acceleration magnitude: ${sensorData.diagnostics!['am']}'),
                    Text('Activity: ${sensorData.formattedActivity}'),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow({
    required String title,
    required String status,
    required bool isHealthy,
    required IconData icon,
    required bool isDark,
  }) {
    final statusColor = isHealthy ? AppColors.success : AppColors.danger;

    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      status,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
