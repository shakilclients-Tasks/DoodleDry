import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../device_connection/presentation/providers/device_connection_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../widgets/heart_rate_monitor_card.dart';
import '../widgets/motion_monitor_card.dart';
import '../widgets/spo2_monitor_card.dart';
import '../widgets/temperature_monitor_card.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorDataAsync = ref.watch(activeSensorDataProvider);
    final liveHistoryAsync = ref.watch(liveBufferProvider);

    final sensorData = sensorDataAsync.value ?? BabySensorData.disconnected();
    final liveHistory = liveHistoryAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Sensor Stream',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heart Rate Monitor
              HeartRateMonitorCard(
                sensorData: sensorData,
                liveHistory: liveHistory,
              ),
              const SizedBox(height: 16),

              // SpO2 Monitor
              Spo2MonitorCard(
                sensorData: sensorData,
                liveHistory: liveHistory,
              ),
              const SizedBox(height: 16),

              // Temperature Monitor
              TemperatureMonitorCard(
                sensorData: sensorData,
                liveHistory: liveHistory,
              ),
              const SizedBox(height: 16),

              // Motion & Fall Detection Monitor
              MotionMonitorCard(
                sensorData: sensorData,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
