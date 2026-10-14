import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../history/data/models/vital_history_entry.dart';
import 'live_vital_sparkline.dart';

class HeartRateMonitorCard extends StatelessWidget {
  final BabySensorData sensorData;
  final List<VitalHistoryEntry> liveHistory;

  const HeartRateMonitorCard({
    super.key,
    required this.sensorData,
    required this.liveHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = sensorData.isDeviceConnected;

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
                      color: AppColors.heartRateBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const PulsingHeartbeatIcon(
                      size: 24,
                      color: AppColors.heartRate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HEART RATE',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isConnected ? 'Status: ${sensorData.heartRateState.displayName}' : 'Device Disconnected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isConnected ? AppColors.success : AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  sensorData.dataQuality.displayName,
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 10,
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
                sensorData.heartRate != null
                    ? sensorData.heartRate!.toStringAsFixed(0)
                    : '--',
                style: AppTextStyles.vitalValueLarge.copyWith(
                  color: AppColors.heartRate,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BPM',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Updated: ${AppDateFormatter.formatRelativeTime(sensorData.timestamp)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Live Sparkline Chart
          Container(
            height: 85,
            padding: const EdgeInsets.only(top: 8),
            child: LiveVitalSparkline(
              points: liveHistory,
              valueSelector: (e) => e.heartRate,
              lineColor: AppColors.heartRate,
              fillColor: AppColors.heartRate,
              minY: 60,
              maxY: 200,
            ),
          ),
        ],
      ),
    );
  }
}
