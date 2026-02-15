import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/properties_provider.dart';
import '../../core/providers/bookings_provider.dart';
import '../../core/providers/locks_provider.dart';
import '../../core/providers/access_codes_provider.dart';
import '../../ui/components/cards/app_card.dart';
import '../../ui/components/buttons/app_button.dart';
import '../../ui/components/loaders/app_skeleton_loader.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upcomingBookings = ref.watch(upcomingBookingsProvider);
    final properties = ref.watch(propertiesProvider);
    final locks = ref.watch(locksProvider);
    final accessCodes = ref.watch(accessCodesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Welcome back! Here\'s what\'s happening with your properties.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet =
                  constraints.maxWidth < 1024 && constraints.maxWidth >= 600;

              int crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 1.2,
                children: [
                  _KPICard(
                    title: 'Properties',
                    value: properties.maybeWhen(
                      data: (props) => props.length.toString(),
                      orElse: () => '—',
                    ),
                    icon: Icons.home_rounded,
                    color: AppColors.accent,
                  ),
                  _KPICard(
                    title: 'Locks',
                    value: locks.maybeWhen(
                      data: (l) => l.length.toString(),
                      orElse: () => '—',
                    ),
                    icon: Icons.lock_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _KPICard(
                    title: 'Upcoming Stays',
                    value: upcomingBookings.maybeWhen(
                      data: (b) => b.length.toString(),
                      orElse: () => '—',
                    ),
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _KPICard(
                    title: 'Active Codes',
                    value: accessCodes.maybeWhen(
                      data: (codes) =>
                          codes.where((c) => c.isActive).length.toString(),
                      orElse: () => '—',
                    ),
                    icon: Icons.vpn_key_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: AppSpacing.xxl),

          // Upcoming Check-ins Section
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              'Upcoming Check-ins',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          upcomingBookings.when(
            data: (bookings) {
              if (bookings.isEmpty) {
                return _EmptyState(
                  icon: Icons.calendar_month_rounded,
                  title: 'No upcoming check-ins',
                  subtitle: 'Sync your iCal URLs to see upcoming bookings.',
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.take(5).length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _BookingCard(booking: booking),
                  );
                },
              );
            },
            loading: () => Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: AppSkeletonCard(lineCount: 2),
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading bookings: $error'),
            ),
          ),

          SizedBox(height: AppSpacing.xxl),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.lg) / 2,
                    child: AppButton(
                      label: 'Sync Locks',
                      onPressed: () {
                        ref.read(locksProvider.notifier).syncLocks();
                      },
                      variant: ButtonVariant.secondary,
                      icon: Icons.refresh_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.lg) / 2,
                    child: AppButton(
                      label: 'Generate Code',
                      onPressed: () {
                        // Navigate to codes page
                      },
                      icon: Icons.vpn_key_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.lg) / 2,
                    child: AppButton(
                      label: 'Add Property',
                      onPressed: () {
                        // Navigate to properties page
                      },
                      variant: ButtonVariant.secondary,
                      icon: Icons.home_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.lg) / 2,
                    child: AppButton(
                      label: 'View All Bookings',
                      onPressed: () {
                        // Navigate to bookings page
                      },
                      variant: ButtonVariant.ghost,
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KPICard extends ConsumerWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysUntilCheckIn =
        booking.checkInDate.difference(DateTime.now()).inDays;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.guestName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${booking.checkInDate.toString().split(' ')[0]} – ${booking.checkOutDate.toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: daysUntilCheckIn <= 1
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  daysUntilCheckIn <= 0 ? 'Today' : 'In $daysUntilCheckIn days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: daysUntilCheckIn <= 1
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          if (booking.guestEmail != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              booking.guestEmail!,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
