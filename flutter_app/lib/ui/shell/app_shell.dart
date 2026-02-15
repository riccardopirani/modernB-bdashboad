import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'sidebar_nav.dart';
import 'top_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({
    Key? key,
    required this.child,
    required this.currentPath,
  }) : super(key: key);

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  bool _sidebarCollapsed = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
      if (_sidebarCollapsed) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    if (!isDesktop && !isTablet) {
      // Mobile: Drawer layout
      return Scaffold(
        appBar: TopBar(onMenuTap: () {
          Scaffold.of(context).openDrawer();
        }),
        drawer: Drawer(
          child: SidebarNav(currentPath: widget.currentPath),
        ),
        body: widget.child,
      );
    }

    // Tablet/Desktop: Sidebar + Content
    return Scaffold(
      body: Row(
        children: [
          // Sidebar with smooth animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: _sidebarCollapsed ? 72 : (isTablet ? 240 : 260),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? AppColors.darkOutline.withOpacity(0.5)
                      : AppColors.outline.withOpacity(0.5),
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: SidebarNav(
                      currentPath: widget.currentPath,
                      collapsed: _sidebarCollapsed,
                    ),
                  ),
                ),
                // Collapse toggle at bottom
                Container(
                  padding: const EdgeInsets.all(12),
                  child: _CollapseButton(
                    collapsed: _sidebarCollapsed,
                    isDark: isDark,
                    onTap: _toggleSidebar,
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Column(
              children: [
                TopBar(onMenuTap: _toggleSidebar),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapseButton extends StatefulWidget {
  final bool collapsed;
  final bool isDark;
  final VoidCallback onTap;

  const _CollapseButton({
    required this.collapsed,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CollapseButton> createState() => _CollapseButtonState();
}

class _CollapseButtonState extends State<_CollapseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              AnimatedRotation(
                turns: widget.collapsed ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: widget.isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 8),
                Text(
                  'Collapse',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
