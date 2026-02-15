import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/theme.dart';

class SidebarNav extends StatelessWidget {
  final String currentPath;
  final bool collapsed;

  const SidebarNav({
    Key? key,
    required this.currentPath,
    this.collapsed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: AppColors.gradientPrimary,
                  ),
                  child: const Center(
                    child: Text(
                      'LF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LockFlow',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Beta',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          // Navigation items
          ..._buildNavItems(context, isDark),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, bool isDark) {
    const items = [
      ('Dashboard', '/dashboard', Icons.grid_view_rounded),
      ('Properties', '/properties', Icons.home_rounded),
      ('Locks', '/locks', Icons.lock_rounded),
      ('Bookings', '/bookings', Icons.calendar_today_rounded),
      ('Codes', '/codes', Icons.vpn_key_rounded),
      ('Guests', '/guests', Icons.people_rounded),
      ('Integrations', '/integrations', Icons.extension_rounded),
    ];

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          'MENU',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      ...items.map((item) {
        final isActive = currentPath.startsWith(item.$2);
        return _NavItem(
          label: item.$1,
          route: item.$2,
          icon: item.$3,
          isActive: isActive,
          collapsed: collapsed,
          isDark: isDark,
        );
      }),
      SizedBox(height: AppSpacing.xl),
      Divider(
        color: isDark ? AppColors.darkOutline : AppColors.outline,
      ),
      SizedBox(height: AppSpacing.lg),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      _NavItem(
        label: 'Billing',
        route: '/billing',
        icon: Icons.credit_card_rounded,
        isActive: currentPath.startsWith('/billing'),
        collapsed: collapsed,
        isDark: isDark,
      ),
      _NavItem(
        label: 'Settings',
        route: '/settings',
        icon: Icons.settings_rounded,
        isActive: currentPath.startsWith('/settings'),
        collapsed: collapsed,
        isDark: isDark,
      ),
    ];
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String route;
  final IconData icon;
  final bool isActive;
  final bool collapsed;
  final bool isDark;

  const _NavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.isActive,
    required this.collapsed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: AppColors.accent,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: collapsed
                ? Icon(
                    icon,
                    size: 20,
                    color: isActive ? AppColors.accent : AppColors.textSecondary,
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isActive
                            ? AppColors.accent
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive
                                ? AppColors.accent
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                          ),
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
