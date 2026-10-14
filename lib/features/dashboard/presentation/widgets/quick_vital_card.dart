import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../../shared/widgets/custom_card.dart';

class QuickVitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String statusText;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final SensorState sensorState;
  final VoidCallback onTap;

  const QuickVitalCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.statusText,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    this.sensorState = SensorState.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: sensorState == SensorState.active
                      ? AppColors.success
                      : (sensorState == SensorState.noData
                          ? AppColors.textMutedLight
                          : (sensorState == SensorState.measuring || sensorState == SensorState.poorSignal)
                              ? AppColors.warning : AppColors.danger),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTextStyles.vitalValueMedium.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: value.length > 5 ? 20 : 26,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit!,
                      style: AppTextStyles.vitalUnit.copyWith(
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: sensorState == SensorState.active
                      ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                      : (sensorState == SensorState.noData
                          ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                          : (sensorState == SensorState.measuring || sensorState == SensorState.poorSignal)
                              ? AppColors.warning : AppColors.danger),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
