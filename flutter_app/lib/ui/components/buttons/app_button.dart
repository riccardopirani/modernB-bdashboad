import 'package:flutter/material.dart';
import 'package:lockflow/core/config/theme.dart';

enum ButtonVariant { primary, secondary, ghost }
enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool disabled;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: variant == ButtonVariant.primary
            ? [
                BoxShadow(
                  color: _getBackgroundColor(isDark).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: (disabled || isLoading) ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: _getPadding(),
            decoration: variant == ButtonVariant.ghost
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: isDark ? AppColors.darkOutline : AppColors.outline,
                    ),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null && !isLoading) ...[
                  Icon(icon, size: 18, color: _getTextColor(isDark)),
                  const SizedBox(width: 8),
                ],
                if (isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_getTextColor(isDark)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  Color _getBackgroundColor(bool isDark) {
    if (disabled) {
      return isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    }
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
      case ButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor(bool isDark) {
    if (disabled) {
      return isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
    }
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
      case ButtonVariant.ghost:
        return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    }
  }
}
