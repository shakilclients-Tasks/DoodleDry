import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum CustomButtonVariant { primary, secondary, outline, danger, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getBgColor() {
      if (onPressed == null) return isDark ? AppColors.cardDark : const Color(0xFFE2E8F0);
      switch (variant) {
        case CustomButtonVariant.primary:
          return AppColors.primary;
        case CustomButtonVariant.secondary:
          return isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        case CustomButtonVariant.outline:
        case CustomButtonVariant.text:
          return Colors.transparent;
        case CustomButtonVariant.danger:
          return AppColors.danger;
      }
    }

    Color getTextColor() {
      if (onPressed == null) return AppColors.textMutedLight;
      switch (variant) {
        case CustomButtonVariant.primary:
        case CustomButtonVariant.danger:
          return Colors.white;
        case CustomButtonVariant.secondary:
          return isDark ? Colors.white : AppColors.textPrimaryLight;
        case CustomButtonVariant.outline:
          return isDark ? AppColors.primaryLight : AppColors.primary;
        case CustomButtonVariant.text:
          return isDark ? AppColors.primaryLight : AppColors.primary;
      }
    }

    Border? getBorder() {
      if (variant == CustomButtonVariant.outline) {
        return Border.all(
          color: onPressed == null
              ? AppColors.borderLight
              : (isDark ? AppColors.primaryLight : AppColors.primary),
          width: 1.5,
        );
      }
      return null;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: getBgColor(),
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: getBorder(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: getTextColor()),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: getTextColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
