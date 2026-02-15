import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool glassmorphic;
  final BoxBorder? border;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.glassmorphic = false,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glassmorphic
            ? (isDark ? AppColors.glassDark : AppColors.glassLight)
            : (isDark ? AppColors.darkSurface : AppColors.surface),
        border: border ??
            Border.all(
              color: isDark ? AppColors.darkOutline : AppColors.outline,
              width: 1,
            ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: glassmorphic
            ? (isDark ? AppElevation.shadowDarkSoft : AppElevation.shadowSoft)
            : AppElevation.shadowSoft,
        backdropFilter: glassmorphic
            ? (null) // Use Glass Kit for better glassmorphism
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: card,
        ),
      );
    }

    return card;
  }
}

class AppCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppCardHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                  ),
                ]
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
