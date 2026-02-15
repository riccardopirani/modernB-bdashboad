import 'package:flutter/material.dart';
import 'package:lockflow/core/config/theme.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? count;

  const AppChip({
    Key? key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          color: selected
              ? AppColors.accent.withOpacity(0.2)
              : (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : (isDark ? AppColors.darkOutline : AppColors.outline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                count!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum BadgeType { success, error, warning, info, accent }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const AppBadge({
    Key? key,
    required this.label,
    this.type = BadgeType.accent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  Map<String, Color> _getColors() {
    switch (type) {
      case BadgeType.success:
        return {
          'bg': AppColors.success.withOpacity(0.1),
          'text': AppColors.success,
        };
      case BadgeType.error:
        return {
          'bg': AppColors.error.withOpacity(0.1),
          'text': AppColors.error,
        };
      case BadgeType.warning:
        return {
          'bg': AppColors.warning.withOpacity(0.1),
          'text': AppColors.warning,
        };
      case BadgeType.info:
        return {
          'bg': AppColors.info.withOpacity(0.1),
          'text': AppColors.info,
        };
      case BadgeType.accent:
        return {
          'bg': AppColors.accent.withOpacity(0.1),
          'text': AppColors.accent,
        };
    }
  }
}
