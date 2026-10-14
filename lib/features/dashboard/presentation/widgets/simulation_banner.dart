import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class SimulationBanner extends StatelessWidget {
  final VoidCallback onTapControls;

  const SimulationBanner({
    super.key,
    required this.onTapControls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.simulationBadgeBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.simulationBadge.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_rounded,
                color: AppColors.simulationBadge,
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SIMULATION MODE ACTIVE",
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.simulationBadge,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Virtual test data (not live patient)",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: onTapControls,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.simulationBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    "Test Panel",
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
