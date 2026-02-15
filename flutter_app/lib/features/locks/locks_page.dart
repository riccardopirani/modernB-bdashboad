import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'package:lockflow/core/providers/locks_provider.dart';
import 'package:lockflow/core/providers/properties_provider.dart';
import 'package:lockflow/ui/components/cards/app_card.dart';
import 'package:lockflow/ui/components/buttons/app_button.dart';
import 'package:lockflow/ui/components/badges/app_chip.dart';
import 'package:lockflow/ui/components/loaders/app_skeleton_loader.dart';

class LocksPage extends ConsumerStatefulWidget {
  const LocksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LocksPage> createState() => _LocksPageState();
}

class _LocksPageState extends ConsumerState<LocksPage> {
  String? _selectedPropertyFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locks = ref.watch(locksProvider);
    final properties = ref.watch(propertiesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Locks',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and manage smart locks from TTLock',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AppButton(
                label: 'Sync Locks',
                onPressed: () {
                  ref.read(locksProvider.notifier).syncLocks();
                },
                icon: Icons.refresh_rounded,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Filters
          properties.when(
            data: (props) {
              if (props.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppChip(
                        label: 'All Properties',
                        selected: _selectedPropertyFilter == null,
                        onTap: () {
                          setState(() => _selectedPropertyFilter = null);
                        },
                      ),
                      ...props.map((prop) {
                        final isSelected =
                            _selectedPropertyFilter == prop.id;
                        return AppChip(
                          label: prop.name,
                          selected: isSelected,
                          onTap: () {
                            setState(() => _selectedPropertyFilter =
                                isSelected ? null : prop.id);
                          },
                        );
                      }),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),

          // Locks List
          locks.when(
            data: (allLocks) {
              final filtered = _selectedPropertyFilter == null
                  ? allLocks
                  : allLocks
                      .where(
                          (l) => l.propertyId == _selectedPropertyFilter)
                      .toList();

              if (filtered.isEmpty) {
                return _EmptyState();
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _LockCard(lock: filtered[index]),
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
              child: Text('Error loading locks: $error'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockCard extends ConsumerWidget {
  final Lock lock;

  const _LockCard({required this.lock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final properties = ref.watch(propertiesProvider);

    String? propertyName;
    properties.whenData((props) {
      final match = props.where((p) => p.id == lock.propertyId);
      propertyName = match.isNotEmpty ? match.first.name : null;
    });

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
                      lock.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lock.model ?? 'Unknown Model',
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (lock.isLocked
                          ? AppColors.error
                          : AppColors.success)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  lock.isLocked
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 20,
                  color:
                      lock.isLocked ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LockInfo(
                label: 'Status',
                child: AppChip(
                  label: lock.isLocked ? 'Locked' : 'Unlocked',
                  selected: lock.isLocked,
                ),
                isDark: isDark,
              ),
              _LockInfo(
                label: 'Battery',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBatteryIcon(lock.electricQuantity),
                      size: 16,
                      color: _getBatteryColor(lock.electricQuantity),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lock.batteryStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getBatteryColor(lock.electricQuantity),
                      ),
                    ),
                  ],
                ),
                isDark: isDark,
              ),
              _LockInfo(
                label: 'Property',
                child: lock.propertyId == null
                    ? const AppChip(label: 'Unassigned')
                    : AppChip(
                        label: propertyName ?? 'Loading...',
                        selected: true,
                      ),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (lock.propertyId != null)
                TextButton(
                  onPressed: () {
                    ref.read(locksProvider.notifier).unassignLock(lock.id);
                  },
                  child: Text(
                    'Unassign',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              const SizedBox(width: 12),
              AppButton(
                label: lock.propertyId == null
                    ? 'Assign Property'
                    : 'View Details',
                onPressed: () {},
                variant: ButtonVariant.secondary,
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon(int? level) {
    if (level == null || level == -1) return Icons.battery_unknown_rounded;
    if (level < 20) return Icons.battery_alert_rounded;
    if (level < 50) return Icons.battery_std_rounded;
    return Icons.battery_full_rounded;
  }

  Color _getBatteryColor(int? level) {
    if (level == null || level == -1) return AppColors.textTertiary;
    if (level < 20) return AppColors.error;
    if (level < 50) return AppColors.warning;
    return AppColors.success;
  }
}

class _LockInfo extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isDark;

  const _LockInfo({
    required this.label,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
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
              Icons.lock_rounded,
              size: 48,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No locks found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your TTLock account and sync locks to manage them here.',
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
