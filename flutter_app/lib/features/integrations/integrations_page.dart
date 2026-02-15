import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'package:lockflow/core/providers/integration_provider.dart';

class IntegrationsPage extends ConsumerWidget {
  const IntegrationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ttlockAsync = ref.watch(ttlockIntegrationProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Integrations',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 4),
          Text('Connect external services to automate your workflow',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),

          // Integration cards grid
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                // TTLock Card
                _IntegrationCard(
                  title: 'TTLock',
                  description:
                      'Connect your TTLock smart locks to manage access codes remotely.',
                  icon: Icons.lock_rounded,
                  iconColor: AppColors.accent,
                  isDark: isDark,
                  status: ttlockAsync.when(
                    loading: () => _IntegrationStatus.loading,
                    error: (_, __) => _IntegrationStatus.error,
                    data: (integration) {
                      if (integration == null) {
                        return _IntegrationStatus.disconnected;
                      }
                      if (!integration.isActive) {
                        return _IntegrationStatus.disconnected;
                      }
                      if (integration.isTokenExpired) {
                        return _IntegrationStatus.expired;
                      }
                      return _IntegrationStatus.connected;
                    },
                  ),
                  onConnect: () async {
                    try {
                      final url = await ref
                          .read(ttlockIntegrationProvider.notifier)
                          .startAuth();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Open this URL to connect: $url'),
                            duration: const Duration(seconds: 10),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  onDisconnect: () async {
                    await ref
                        .read(ttlockIntegrationProvider.notifier)
                        .disconnect();
                  },
                  onSync: () async {
                    try {
                      await ref
                          .read(ttlockIntegrationProvider.notifier)
                          .syncLocks();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Locks synced!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync error: $e')),
                        );
                      }
                    }
                  },
                ),

                // iCal Card
                _IntegrationCard(
                  title: 'iCal (Airbnb / Booking)',
                  description:
                      'Sync bookings automatically from Airbnb, Booking.com, or any iCal source.',
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.success,
                  isDark: isDark,
                  status: _IntegrationStatus.connected,
                  onConnect: () {},
                  info:
                      'Add iCal URLs per property in the Properties section. Syncs every 15 minutes.',
                ),

                // Stripe Card
                _IntegrationCard(
                  title: 'Stripe',
                  description:
                      'Manage billing and subscriptions through Stripe.',
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF635BFF),
                  isDark: isDark,
                  status: _IntegrationStatus.connected,
                  onConnect: () {},
                  info: 'Configured via environment. Manage billing in the Billing section.',
                ),

                // Messaging Card (future)
                _IntegrationCard(
                  title: 'Messaging (Resend / Twilio)',
                  description:
                      'Send access codes to guests via email or SMS automatically.',
                  icon: Icons.message_rounded,
                  iconColor: AppColors.warning,
                  isDark: isDark,
                  status: _IntegrationStatus.comingSoon,
                  onConnect: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _IntegrationStatus {
  connected,
  disconnected,
  expired,
  loading,
  error,
  comingSoon,
}

class _IntegrationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final _IntegrationStatus status;
  final VoidCallback onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onSync;
  final String? info;

  const _IntegrationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.status,
    required this.onConnect,
    this.onDisconnect,
    this.onSync,
    this.info,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: status == _IntegrationStatus.connected
              ? AppColors.success.withOpacity(0.3)
              : (isDark ? AppColors.darkOutline : AppColors.outline),
          width: status == _IntegrationStatus.connected ? 1.5 : 1,
        ),
        boxShadow: isDark ? null : AppElevation.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const Spacer(),
              _StatusBadge(status: status, isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              info ?? description,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          if (status == _IntegrationStatus.disconnected ||
              status == _IntegrationStatus.expired)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onConnect,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Connect'),
              ),
            )
          else if (status == _IntegrationStatus.connected &&
              (onSync != null || onDisconnect != null))
            Row(
              children: [
                if (onSync != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSync,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm)),
                      ),
                      child: const Text('Sync'),
                    ),
                  ),
                if (onSync != null && onDisconnect != null)
                  const SizedBox(width: 8),
                if (onDisconnect != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDisconnect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm)),
                      ),
                      child: const Text('Disconnect'),
                    ),
                  ),
              ],
            )
          else if (status == _IntegrationStatus.comingSoon)
            const SizedBox.shrink()
          else if (status == _IntegrationStatus.loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _IntegrationStatus status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case _IntegrationStatus.connected:
        color = AppColors.success;
        label = 'Connected';
        break;
      case _IntegrationStatus.disconnected:
        color = isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
        label = 'Not Connected';
        break;
      case _IntegrationStatus.expired:
        color = AppColors.warning;
        label = 'Expired';
        break;
      case _IntegrationStatus.loading:
        color = AppColors.info;
        label = 'Loading...';
        break;
      case _IntegrationStatus.error:
        color = AppColors.error;
        label = 'Error';
        break;
      case _IntegrationStatus.comingSoon:
        color = AppColors.warning;
        label = 'Coming Soon';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
