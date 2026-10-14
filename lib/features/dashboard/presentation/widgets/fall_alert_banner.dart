import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class FallAlertBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onViewDetails;

  const FallAlertBanner({
    super.key,
    required this.onDismiss,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "⚠ FALL EVENT DETECTED",
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Sudden movement impact detected by wearable. Check on the baby immediately.",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: onViewDetails,
                      child: Text(
                        "View Details",
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    InkWell(
                      onTap: onDismiss,
                      child: Text(
                        "Dismiss / Seen",
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
