import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;

  const TopBar({
    Key? key,
    this.onMenuTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Menu button (mobile/tablet)
          if (MediaQuery.of(context).size.width <= 1024)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onMenuTap,
              ),
            ),
          // Search bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                onTap: () {
                  // Trigger command palette on tap
                  _showCommandPalette(context);
                },
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Search or press Cmd+K...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          // Right actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notifications
                Tooltip(
                  message: 'Notifications',
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Dark mode toggle
                Tooltip(
                  message: 'Theme',
                  child: IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                    onPressed: () {
                      // Theme toggle handled by app-level provider
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Profile menu
                Tooltip(
                  message: 'Profile',
                  child: PopupMenuButton(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        'JD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text('Profile'),
                        onTap: () {},
                      ),
                      PopupMenuItem(
                        child: Text('Settings'),
                        onTap: () {},
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: Text('Logout'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommandPalette(BuildContext context) {
    showSearch(
      context: context,
      delegate: _CommandPaletteDelegate(),
    );
  }
}

class _CommandPaletteDelegate extends SearchDelegate<String> {
  final commands = [
    {'label': 'Go to Dashboard', 'action': '/dashboard'},
    {'label': 'Go to Properties', 'action': '/properties'},
    {'label': 'Go to Locks', 'action': '/locks'},
    {'label': 'Go to Bookings', 'action': '/bookings'},
    {'label': 'Go to Codes', 'action': '/codes'},
    {'label': 'New Property', 'action': '/properties/new'},
    {'label': 'New Booking', 'action': '/bookings/new'},
    {'label': 'Settings', 'action': '/settings'},
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildCommandList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildCommandList(context);
  }

  Widget _buildCommandList(BuildContext context) {
    final results = query.isEmpty
        ? commands
        : commands
            .where((cmd) =>
                cmd['label']!.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final cmd = results[index];
        return ListTile(
          title: Text(cmd['label']!),
          onTap: () {
            close(context, cmd['action']!);
            // Navigate based on action
          },
        );
      },
    );
  }
}
