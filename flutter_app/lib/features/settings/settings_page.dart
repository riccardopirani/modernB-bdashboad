import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'package:lockflow/core/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _orgNameController = TextEditingController();
  bool _autoGenerateCodes = true;
  bool _notifyOnCheckIn = true;
  bool _notifyOnCodeGenerated = true;
  String _defaultCheckInTime = '15:00';
  String _defaultCheckOutTime = '11:00';

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text('Manage your account and organization preferences',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),

            // Account Section
            _SectionCard(
              title: 'Account',
              icon: Icons.person_rounded,
              isDark: isDark,
              children: [
                user.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading user'),
                  data: (u) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Email',
                        value: u?.email ?? 'Not signed in',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'User ID',
                        value: u?.id ?? '-',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showChangePasswordDialog(context),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Change Password'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).signOut();
                      },
                      icon: const Icon(Icons.logout_rounded,
                          size: 16, color: AppColors.error),
                      label: const Text('Sign Out',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Organization Section
            _SectionCard(
              title: 'Organization',
              icon: Icons.business_rounded,
              isDark: isDark,
              children: [
                TextField(
                  controller: _orgNameController,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    hintText: 'My Property Company',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Organization updated!')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Automation Section
            _SectionCard(
              title: 'Automation',
              icon: Icons.auto_mode_rounded,
              isDark: isDark,
              children: [
                SwitchListTile(
                  title: const Text('Auto-generate access codes'),
                  subtitle: const Text(
                      'Automatically create codes for confirmed bookings'),
                  value: _autoGenerateCodes,
                  onChanged: (v) => setState(() => _autoGenerateCodes = v),
                  activeColor: AppColors.accent,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default Check-in Time'),
                  trailing: DropdownButton<String>(
                    value: _defaultCheckInTime,
                    items: ['14:00', '15:00', '16:00']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _defaultCheckInTime = v ?? '15:00'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default Check-out Time'),
                  trailing: DropdownButton<String>(
                    value: _defaultCheckOutTime,
                    items: ['10:00', '11:00', '12:00']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _defaultCheckOutTime = v ?? '11:00'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notifications Section
            _SectionCard(
              title: 'Notifications',
              icon: Icons.notifications_rounded,
              isDark: isDark,
              children: [
                SwitchListTile(
                  title: const Text('Check-in notifications'),
                  subtitle: const Text('Get notified when guests check in'),
                  value: _notifyOnCheckIn,
                  onChanged: (v) => setState(() => _notifyOnCheckIn = v),
                  activeColor: AppColors.accent,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Code generation alerts'),
                  subtitle: const Text(
                      'Notify when access codes are auto-generated'),
                  value: _notifyOnCodeGenerated,
                  onChanged: (v) =>
                      setState(() => _notifyOnCodeGenerated = v),
                  activeColor: AppColors.accent,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Danger Zone
            _SectionCard(
              title: 'Danger Zone',
              icon: Icons.warning_amber_rounded,
              isDark: isDark,
              borderColor: AppColors.error.withOpacity(0.3),
              children: [
                Text(
                  'Deleting your organization will permanently remove all properties, locks, bookings, and access codes.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_forever,
                      size: 16, color: AppColors.error),
                  label: const Text('Delete Organization',
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current Password'),
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated!')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization?'),
        content: const Text(
            'This action cannot be undone. All data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;
  final Color? borderColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor ??
              (isDark ? AppColors.darkOutline : AppColors.outline),
        ),
        boxShadow: isDark ? null : AppElevation.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
