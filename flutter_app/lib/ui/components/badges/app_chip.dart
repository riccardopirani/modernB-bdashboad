import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class AppChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final bool selected;
  final void Function()? onTap;

  const AppChip({
    Key? key,
    required this.label,
    this.onDelete,
    this.selected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.2)
                : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
            border: Border.all(
              color: selected ? AppColors.accent : (isDark ? AppColors.darkOutline : AppColors.outline),
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              if (onDelete != null) ...[
                SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const AppBadge({
    Key? key,
    required this.label,
    this.variant = BadgeVariant.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors['text'],
        ),
      ),
    );
  }

  Map<String, Color> _getColors(bool isDark) {
    switch (variant) {
      case BadgeVariant.success:
        return {
          'bg': AppColors.success.withOpacity(0.1),
          'text': AppColors.success,
        };
      case BadgeVariant.error:
        return {
          'bg': AppColors.error.withOpacity(0.1),
          'text': AppColors.error,
        };
      case BadgeVariant.warning:
        return {
          'bg': AppColors.warning.withOpacity(0.1),
          'text': AppColors.warning,
        };
      case BadgeVariant.info:
        return {
          'bg': AppColors.info.withOpacity(0.1),
          'text': AppColors.info,
        };
      case BadgeVariant.primary:
        return {
          'bg': AppColors.accent.withOpacity(0.1),
          'text': AppColors.accent,
        };
    }
  }
}

enum BadgeVariant { primary, success, error, warning, info }
