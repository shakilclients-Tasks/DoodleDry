import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/vitals_evaluator.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../device_connection/data/models/device_connection_state.dart';

class DeviceStatusCard extends StatelessWidget {
  final BabySensorData sensorData;
  final DeviceConnectionState connectionState;
  final VoidCallback onDiagnosticsTap;
  final VoidCallback onDeviceTap;

  const DeviceStatusCard({
    super.key,
    required this.sensorData,
    required this.connectionState,
    required this.onDiagnosticsTap,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = sensorData.isDeviceConnected && connectionState.isConnectedOrReceiving;

    Color statusColor = isConnected ? AppColors.success : AppColors.danger;
    String statusText = isConnected ? 'Connected' : 'Disconnected';
    if (connectionState == DeviceConnectionState.scanning ||
        connectionState == DeviceConnectionState.connecting ||
        connectionState == DeviceConnectionState.reconnecting) {
      statusColor = AppColors.warning;
      statusText = connectionState.displayName;
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onDiagnosticsTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_suggest_rounded,
                        size: 16,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Diagnostics',
                        style: AppTextStyles.label.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEARABLE MODULE',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sensorData.deviceId,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sensorData.batteryPercentage != null && sensorData.batteryPercentage! <= 20
                            ? Icons.battery_alert_rounded
                            : Icons.battery_std_rounded,
                        size: 18,
                        color: VitalsEvaluator.getBatteryColor(sensorData.batteryPercentage),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sensorData.batteryPercentage == null ? '-- %' : '${sensorData.batteryPercentage}%',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: VitalsEvaluator.getBatteryColor(sensorData.batteryPercentage),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth_rounded,
                    size: 16,
                    color: isConnected ? AppColors.secondary : AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'Bluetooth Connected' : 'Waiting for Device',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                !isConnected && sensorData.dataQuality == SensorDataQuality.stale
                    ? 'Connection Lost'
                    : sensorData.dataQuality == SensorDataQuality.stale
                        ? 'Updated: Updating...'
                        : sensorData.isDeviceConnected
                            ? 'Updated: ${AppDateFormatter.formatRelativeTime(sensorData.timestamp)}'
                            : 'No packet yet',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
