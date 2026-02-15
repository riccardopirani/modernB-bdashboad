import 'package:flutter/material.dart';
import 'package:lockflow/core/config/theme.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Menu button (mobile/tablet)
          if (MediaQuery.of(context).size.width <= 1024)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onMenuTap,
              ),
            ),
          // Search bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                onTap: () {
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
                    horizontal: 16,
                    vertical: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                // Profile menu
                Tooltip(
                  message: 'Profile',
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 48),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accent,
                      child: const Text(
                        'JD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'profile',
                        child: Text('Profile'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                    onSelected: (value) {
                      // Handle selection
                    },
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
          },
        );
      },
    );
  }
}
