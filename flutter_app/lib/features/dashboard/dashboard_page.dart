import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'package:lockflow/core/providers/properties_provider.dart';
import 'package:lockflow/core/providers/bookings_provider.dart';
import 'package:lockflow/core/providers/locks_provider.dart';
import 'package:lockflow/core/providers/access_codes_provider.dart';
import 'package:lockflow/ui/components/cards/app_card.dart';
import 'package:lockflow/ui/components/buttons/app_button.dart';
import 'package:lockflow/ui/components/loaders/app_skeleton_loader.dart';

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 4),
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
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
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
                    color: AppColors.success,
                  ),
                  _KPICard(
                    title: 'Upcoming Stays',
                    value: upcomingBookings.maybeWhen(
                      data: (b) => b.length.toString(),
                      orElse: () => '—',
                    ),
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.warning,
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

          const SizedBox(height: 32),

          // Upcoming Check-ins Section
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookingCard(booking: booking),
                  );
                },
              );
            },
            loading: () => Column(
              children: List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: AppSkeletonCard(lineCount: 2),
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading bookings: $error'),
            ),
          ),

          const SizedBox(height: 32),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2,
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
                        : (constraints.maxWidth - 16) / 2,
                    child: AppButton(
                      label: 'Generate Code',
                      onPressed: () {},
                      icon: Icons.vpn_key_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2,
                    child: AppButton(
                      label: 'Add Property',
                      onPressed: () {},
                      variant: ButtonVariant.secondary,
                      icon: Icons.home_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2,
                    child: AppButton(
                      label: 'View All Bookings',
                      onPressed: () {},
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

class _KPICard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: color),
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

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: daysUntilCheckIn <= 1
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  daysUntilCheckIn <= 0
                      ? 'Today'
                      : 'In $daysUntilCheckIn days',
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
            const SizedBox(height: 8),
            Text(
              booking.guestEmail!,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceVariant,
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
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
