import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../../shared/widgets/custom_card.dart';

class MotionMonitorCard extends StatelessWidget {
  final BabySensorData sensorData;

  const MotionMonitorCard({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMotionLive = sensorData.isDeviceConnected && sensorData.motionState == SensorState.active;
    final isFall = isMotionLive && sensorData.fallDetected == true;

    return CustomCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      border: isFall ? Border.all(color: AppColors.danger, width: 2) : null,
      color: isFall ? (isDark ? const Color(0xFF3B1219) : AppColors.dangerBg) : null,
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
                      color: isFall ? AppColors.danger : AppColors.motionBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isFall ? Icons.warning_rounded : Icons.directions_run_rounded,
                      size: 24,
                      color: isFall ? Colors.white : AppColors.motion,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOTION & FALL DETECTION',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isFall ? AppColors.danger : null,
                        ),
                      ),
                      Text(
                        isFall
                            ? '⚠ Sudden Impact / Drop Detected'
                            : isMotionLive ? 'Monitoring Active' : 'Sensor Unavailable',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isFall ? AppColors.danger : AppColors.success,
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
                  color: isFall
                      ? AppColors.danger
                      : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isMotionLive ? sensorData.formattedActivity.toUpperCase() : '--',
                  style: AppTextStyles.label.copyWith(
                    color: isFall ? Colors.white : AppColors.motion,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Fall Status Banner
          if (isFall) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Check the baby immediately. Sudden acceleration spike recorded.",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3-Axis Accelerometer Visualizer
          Text(
            "WEARABLE ACCELEROMETER VECTORS (m/s²)",
            style: AppTextStyles.label.copyWith(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAxisTile("X-Axis", isMotionLive ? sensorData.accelerationX : null, isDark),
              const SizedBox(width: 8),
              _buildAxisTile("Y-Axis", isMotionLive ? sensorData.accelerationY : null, isDark),
              const SizedBox(width: 8),
              _buildAxisTile("Z-Axis", isMotionLive ? sensorData.accelerationZ : null, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisTile(String axis, double? val, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              axis,
              style: AppTextStyles.label.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val != null ? val.toStringAsFixed(2) : '--',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
