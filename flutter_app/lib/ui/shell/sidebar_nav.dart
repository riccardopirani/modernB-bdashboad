import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockflow/core/config/theme.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo with pulse animation
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                _AnimatedLogo(collapsed: collapsed),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          'BETA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
      ('Integrations', '/integrations', Icons.extension_rounded),
    ];

    return [
      if (!collapsed)
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            'MENU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ...items.map((item) {
        final isActive = currentPath.startsWith(item.$2);
        return _HoverNavItem(
          label: item.$1,
          route: item.$2,
          icon: item.$3,
          isActive: isActive,
          collapsed: collapsed,
          isDark: isDark,
        );
      }),
      const SizedBox(height: 24),
      Divider(
        color: isDark ? AppColors.darkOutline : AppColors.outline,
      ),
      const SizedBox(height: 16),
      if (!collapsed)
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      _HoverNavItem(
        label: 'Billing',
        route: '/billing',
        icon: Icons.credit_card_rounded,
        isActive: currentPath.startsWith('/billing'),
        collapsed: collapsed,
        isDark: isDark,
      ),
      _HoverNavItem(
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

class _AnimatedLogo extends StatefulWidget {
  final bool collapsed;

  const _AnimatedLogo({required this.collapsed});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              colors: [
                AppColors.accent,
                Color.lerp(AppColors.accent, const Color(0xFF8B5CF6),
                    _controller.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3 * _controller.value),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'LF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoverNavItem extends StatefulWidget {
  final String label;
  final String route;
  final IconData icon;
  final bool isActive;
  final bool collapsed;
  final bool isDark;

  const _HoverNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.isActive,
    required this.collapsed,
    required this.isDark,
  });

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isActive || _isHovered;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? (widget.isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant)
                  : (_isHovered
                      ? (widget.isDark
                          ? AppColors.darkSurfaceVariant.withOpacity(0.5)
                          : AppColors.surfaceVariant.withOpacity(0.5))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: widget.collapsed
                ? Tooltip(
                    message: widget.label,
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: isHighlighted
                            ? AppColors.accent
                            : (widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: widget.isActive ? 3 : 0,
                        height: 16,
                        margin: EdgeInsets.only(
                            right: widget.isActive ? 10 : 0),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      Icon(
                        widget.icon,
                        size: 18,
                        color: isHighlighted
                            ? AppColors.accent
                            : (widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isHighlighted
                                ? (widget.isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary)
                                : (widget.isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
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

// AnimatedBuilder is essentially AnimatedWidget for inline use
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    Key? key,
    required Animation<double> animation,
    required this.builder,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
