import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/theme.dart';
import '../../core/providers/properties_provider.dart';
import '../../ui/components/cards/app_card.dart';
import '../../ui/components/buttons/app_button.dart';
import '../../ui/components/inputs/app_text_field.dart';
import '../../ui/components/loaders/app_skeleton_loader.dart';
import '../../ui/components/badges/app_chip.dart';

class PropertiesPage extends ConsumerStatefulWidget {
  const PropertiesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends ConsumerState<PropertiesPage> {
  bool _showCreateDialog = false;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _icalUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _icalUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _icalUrlController.clear();
  }

  Future<void> _createProperty() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property name is required')),
      );
      return;
    }

    await ref.read(propertiesProvider.notifier).createProperty(
          _nameController.text,
          _addressController.text.isEmpty ? null : _addressController.text,
          _cityController.text.isEmpty ? null : _cityController.text,
          _stateController.text.isEmpty ? null : _stateController.text,
          _icalUrlController.text.isEmpty ? null : _icalUrlController.text,
        );

    _resetForm();
    setState(() => _showCreateDialog = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    'Properties',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Manage your rental properties and booking calendars',
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
                label: 'Add Property',
                onPressed: () {
                  setState(() => _showCreateDialog = true);
                  _showCreateDialog;
                },
                icon: Icons.add_rounded,
              ),
            ],
          ),

          SizedBox(height: AppSpacing.xxl),

          // Properties List
          properties.when(
            data: (props) {
              if (props.isEmpty) {
                return _EmptyState();
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 1 : 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                ),
                itemCount: props.length,
                itemBuilder: (context, index) {
                  return _PropertyCard(property: props[index]);
                },
              );
            },
            loading: () => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width < 600 ? 1 : 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return AppSkeletonCard(lineCount: 3);
              },
            ),
            error: (error, stack) => Center(
              child: Text('Error loading properties: $error'),
            ),
          ),

          // Create Dialog
          if (_showCreateDialog)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Property',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Property Name',
                      hint: 'e.g., Beachfront Villa',
                      controller: _nameController,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Address',
                      hint: 'Street address',
                      controller: _addressController,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'City',
                            hint: 'City',
                            controller: _cityController,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 80,
                          child: AppTextField(
                            label: 'State',
                            hint: 'State',
                            controller: _stateController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'iCal URL',
                      hint: 'https://calendar.google.com/calendar/ical/...',
                      controller: _icalUrlController,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          label: 'Cancel',
                          onPressed: () {
                            _resetForm();
                            setState(() => _showCreateDialog = false);
                          },
                          variant: ButtonVariant.ghost,
                        ),
                        SizedBox(width: AppSpacing.md),
                        AppButton(
                          label: 'Create',
                          onPressed: _createProperty,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  final Property property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: () {
        // Navigate to property detail
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  property.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.home_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            property.address ?? 'No address',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (property.city != null) ...[
            Text(
              '${property.city}, ${property.state ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (property.icalUrl != null)
                AppChip(
                  label: 'iCal Synced',
                  selected: true,
                )
              else
                AppChip(
                  label: 'No iCal',
                ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Edit'),
                    onTap: () {
                      // Edit property
                    },
                  ),
                  PopupMenuItem(
                    child: Text('Sync iCal'),
                    onTap: () {
                      ref
                          .read(propertiesProvider.notifier)
                          .syncIcalBookings(property.id);
                    },
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      ref.read(propertiesProvider.notifier).deleteProperty(property.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
              Icons.home_rounded,
              size: 48,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No properties yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first property to get started managing guest access.',
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
