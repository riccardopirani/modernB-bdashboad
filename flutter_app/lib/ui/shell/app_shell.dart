import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/theme.dart';
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

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet =
        MediaQuery.of(context).size.width > 600 && !isDesktop;

    if (!isDesktop) {
      // Mobile/Tablet: Drawer layout
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: TopBar(
            onMenuTap: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        drawer: SidebarNav(currentPath: widget.currentPath),
        body: widget.child,
      );
    }

    // Desktop: Sidebar + Content
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarCollapsed ? 80 : 280,
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            border: Border(
              right: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: SidebarNav(
                    currentPath: widget.currentPath,
                    collapsed: _sidebarCollapsed,
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.lg,
                  right: _sidebarCollapsed ? AppSpacing.sm : AppSpacing.md,
                  child: Tooltip(
                    message: _sidebarCollapsed ? 'Expand' : 'Collapse',
                    child: IconButton(
                      icon: Icon(
                        _sidebarCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          _sidebarCollapsed = !_sidebarCollapsed;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: TopBar(
                    onMenuTap: () {
                      setState(() {
                        _sidebarCollapsed = !_sidebarCollapsed;
                      });
                    },
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height - 64,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
