import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;

  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool disabled = isDisabled || isLoading;

    return Material(
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isDark, disabled),
            border: _getBorder(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: variant == ButtonVariant.primary && !disabled
                ? AppElevation.shadowMedium
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !isLoading) ...[
                Icon(
                  icon,
                  size: _getIconSize(),
                  color: _getTextColor(isDark, disabled),
                ),
                SizedBox(width: AppSpacing.sm),
              ],
              if (isLoading)
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      _getTextColor(isDark, disabled),
                    ),
                  ),
                )
              else
                Text(
                  label,
                  style: _getTextStyle(),
                ),
              if (isLoading) SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );
      case ButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case ButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  Color _getBackgroundColor(bool isDark, bool disabled) {
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

  Color _getTextColor(bool isDark, bool disabled) {
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

  Border? _getBorder(bool isDark) {
    if (variant == ButtonVariant.ghost || variant == ButtonVariant.secondary) {
      return Border.all(
        color: isDark ? AppColors.darkOutline : AppColors.outline,
      );
    }
    return null;
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
      case ButtonSize.medium:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
      case ButtonSize.large:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    }
  }
}

enum ButtonVariant { primary, secondary, ghost }
enum ButtonSize { small, medium, large }
