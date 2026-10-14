import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../history/data/models/vital_history_entry.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'live_vital_sparkline.dart';

class TemperatureMonitorCard extends ConsumerWidget {
  final BabySensorData sensorData;
  final List<VitalHistoryEntry> liveHistory;

  const TemperatureMonitorCard({
    super.key,
    required this.sensorData,
    required this.liveHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = sensorData.isDeviceConnected;

    final isFahrenheit = settings.isFahrenheit;
    final plottedTemperatures = liveHistory
        .map((entry) => entry.temperature)
        .whereType<double>()
        .map((value) => isFahrenheit ? value * 9 / 5 + 32 : value)
        .toList();
    final chartMin = plottedTemperatures.isEmpty
        ? (isFahrenheit ? 30.0 : 0.0)
        : plottedTemperatures.reduce((a, b) => a < b ? a : b) - 1;
    final chartMax = plottedTemperatures.isEmpty
        ? (isFahrenheit ? 32.0 : 2.0)
        : plottedTemperatures.reduce((a, b) => a > b ? a : b) + 1;
    String displayTemp = '--';
    if (isConnected &&
        sensorData.temperatureState == SensorState.active &&
        sensorData.temperature != null) {
      if (isFahrenheit) {
        displayTemp = sensorData.temperatureInFahrenheit!.toStringAsFixed(1);
      } else {
        displayTemp = sensorData.temperature!.toStringAsFixed(1);
      }
    }

    return CustomCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.temperatureBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.thermostat_rounded,
                      size: 24,
                      color: AppColors.temperature,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'IR SURFACE TEMP',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.temperature.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MLX90614 IR',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.temperature,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        !isConnected
                            ? 'Device Disconnected'
                            : (sensorData.temperatureState == SensorState.active
                                ? 'MLX90614 object reading • not core body temp'
                                : 'Awaiting a valid MLX90614 reading'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: !isConnected
                              ? AppColors.danger
                              : (sensorData.temperatureState ==
                                      SensorState.active
                                  ? AppColors.success
                                  : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight)),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Unit Switcher (Celsius / Fahrenheit)
              InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).toggleTemperatureUnit();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    isFahrenheit ? 'Switch to °C' : 'Switch to °F',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayTemp,
                style: AppTextStyles.vitalValueLarge.copyWith(
                  color: AppColors.temperature,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isFahrenheit ? '°F' : '°C',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Updated: ${AppDateFormatter.formatRelativeTime(sensorData.timestamp)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (isConnected &&
              sensorData.temperatureState == SensorState.active &&
              sensorData.ambientTemperature != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Text(
                  isFahrenheit
                      ? 'Sensor Ambient: ${sensorData.ambientTemperatureInFahrenheit!.toStringAsFixed(1)} °F'
                      : 'Sensor Ambient: ${sensorData.ambientTemperature!.toStringAsFixed(1)} °C',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Live Sparkline Chart
          Container(
            height: 85,
            padding: const EdgeInsets.only(top: 8),
            child: LiveVitalSparkline(
              points: liveHistory,
              valueSelector: (e) => e.temperature == null
                  ? null
                  : isFahrenheit
                      ? (e.temperature! * 9 / 5 + 32)
                      : e.temperature,
              lineColor: AppColors.temperature,
              fillColor: AppColors.temperature,
              minY: chartMin,
              maxY: chartMax,
            ),
          ),
        ],
      ),
    );
  }
}
