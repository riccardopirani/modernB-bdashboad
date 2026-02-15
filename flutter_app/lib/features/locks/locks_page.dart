import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/theme.dart';
import '../../core/providers/locks_provider.dart';
import '../../core/providers/properties_provider.dart';
import '../../ui/components/cards/app_card.dart';
import '../../ui/components/buttons/app_button.dart';
import '../../ui/components/badges/app_chip.dart';
import '../../ui/components/loaders/app_skeleton_loader.dart';

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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  SizedBox(height: AppSpacing.xs),
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

          SizedBox(height: AppSpacing.xl),

          // Filters
          properties.when(
            data: (props) {
              if (props.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppChip(
                        label: 'All Properties',
                        selected: _selectedPropertyFilter == null,
                        onTap: () {
                          setState(() => _selectedPropertyFilter = null);
                        },
                      ),
                      ...props.map((prop) {
                        final isSelected = _selectedPropertyFilter == prop.id;
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
                      .where((l) => l.propertyId == _selectedPropertyFilter)
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _LockCard(lock: filtered[index]),
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
      propertyName =
          props.firstWhere((p) => p.id == lock.propertyId, orElse: () => props.first).name;
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
                    SizedBox(height: AppSpacing.xs),
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
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  lock.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size: 20,
                  color: lock.isLocked ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Lock Status & Battery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AppChip(
                    label: lock.isLocked ? 'Locked' : 'Unlocked',
                    selected: lock.isLocked,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battery',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        _getBatteryIcon(lock.electricQuantity),
                        size: 16,
                        color: _getBatteryColor(lock.electricQuantity),
                      ),
                      SizedBox(width: AppSpacing.xs),
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
                ],
              ),
              if (lock.propertyId == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    AppChip(label: 'Unassigned'),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    AppChip(
                      label: propertyName ?? 'Loading...',
                      selected: true,
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (lock.propertyId != null)
                TextButton(
                  onPressed: () {
                    ref
                        .read(locksProvider.notifier)
                        .unassignLock(lock.id);
                  },
                  child: Text(
                    'Unassign',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              SizedBox(width: AppSpacing.md),
              AppButton(
                label: lock.propertyId == null ? 'Assign Property' : 'View Details',
                onPressed: () {
                  // Open assignment or details dialog
                },
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

class _EmptyState extends StatelessWidget {
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
              Icons.lock_rounded,
              size: 48,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No locks found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Connect your TTLock account and sync locks to manage them here.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
