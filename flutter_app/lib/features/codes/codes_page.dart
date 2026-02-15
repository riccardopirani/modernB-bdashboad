import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'package:lockflow/core/providers/access_codes_provider.dart';
import 'package:lockflow/core/providers/locks_provider.dart';
import 'package:lockflow/core/providers/properties_provider.dart';
import 'package:intl/intl.dart';

class CodesPage extends ConsumerStatefulWidget {
  const CodesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CodesPage> createState() => _CodesPageState();
}

class _CodesPageState extends ConsumerState<CodesPage> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codesAsync = ref.watch(accessCodesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Access Codes',
                        style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 4),
                    Text('Generate and manage door access codes',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showGenerateDialog(context, isDark),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Generate Code'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filter chips
          Wrap(
            spacing: 8,
            children: ['all', 'active', 'pending', 'expired', 'revoked']
                .map((status) => ChoiceChip(
                      label: Text(status == 'all'
                          ? 'All'
                          : status[0].toUpperCase() + status.substring(1)),
                      selected: _filterStatus == status,
                      onSelected: (_) =>
                          setState(() => _filterStatus = status),
                      selectedColor: AppColors.accent.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _filterStatus == status
                            ? AppColors.accent
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                        fontWeight: _filterStatus == status
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Codes list
          Expanded(
            child: codesAsync.when(
              loading: () => _buildSkeletonGrid(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (codes) {
                final filtered = _filterStatus == 'all'
                    ? codes
                    : codes.where((c) {
                        if (_filterStatus == 'expired') return c.isExpired;
                        return c.status == _filterStatus;
                      }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _CodeCard(
                        code: filtered[index], isDark: isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vpn_key_rounded,
              size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text('No access codes yet',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Generate codes manually or enable automation for bookings',
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _GenerateCodeDialog(isDark: isDark),
    );
  }
}

class _CodeCard extends ConsumerWidget {
  final AccessCode code;
  final bool isDark;

  const _CodeCard({required this.code, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: code.isActive
              ? AppColors.success.withOpacity(0.3)
              : (isDark ? AppColors.darkOutline : AppColors.outline),
        ),
        boxShadow: isDark ? null : AppElevation.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.vpn_key_rounded,
                    size: 18, color: _statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (code.guestName != null)
                      Text(code.guestName!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          )),
                    Text(
                      code.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary),
                onSelected: (value) {
                  if (value == 'revoke') {
                    ref.read(accessCodesProvider.notifier).revokeCode(code.id);
                  } else if (value == 'copy') {
                    Clipboard.setData(ClipboardData(text: code.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  } else if (value == 'send_email') {
                    ref
                        .read(accessCodesProvider.notifier)
                        .sendCode(code.id, 'email');
                  }
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'copy', child: Text('Copy Code')),
                  const PopupMenuItem(
                      value: 'send_email', child: Text('Send via Email')),
                  if (code.isActive)
                    const PopupMenuItem(
                        value: 'revoke',
                        child: Text('Revoke',
                            style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Code display
          Center(
            child: Text(
              code.code,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                fontFamily: 'monospace',
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          // Validity
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${DateFormat('MMM d, HH:mm').format(code.validFrom)} → ${DateFormat('MMM d, HH:mm').format(code.validUntil)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    if (code.isExpired) return AppColors.warning;
    switch (code.status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.info;
      case 'revoked':
        return AppColors.error;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}

class _GenerateCodeDialog extends ConsumerStatefulWidget {
  final bool isDark;

  const _GenerateCodeDialog({required this.isDark});

  @override
  ConsumerState<_GenerateCodeDialog> createState() =>
      _GenerateCodeDialogState();
}

class _GenerateCodeDialogState extends ConsumerState<_GenerateCodeDialog> {
  final _guestNameController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _selectedLockId;
  String? _selectedPropertyId;
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Generate a random 6-digit code
    final code = (100000 + (DateTime.now().microsecond * 7) % 900000).toString();
    _codeController.text = code;
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final locks = ref.watch(locksProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate Access Code',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextField(
              controller: _guestNameController,
              decoration: const InputDecoration(labelText: 'Guest Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _guestEmailController,
              decoration: const InputDecoration(labelText: 'Guest Email'),
            ),
            const SizedBox(height: 12),
            properties.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading properties'),
              data: (props) => DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                decoration: const InputDecoration(labelText: 'Property'),
                items: props
                    .map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPropertyId = v),
              ),
            ),
            const SizedBox(height: 12),
            locks.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading locks'),
              data: (lockList) {
                final filtered = _selectedPropertyId != null
                    ? lockList
                        .where((l) => l.propertyId == _selectedPropertyId)
                        .toList()
                    : lockList;
                return DropdownButtonFormField<String>(
                  value: _selectedLockId,
                  decoration: const InputDecoration(labelText: 'Lock'),
                  items: filtered
                      .map((l) =>
                          DropdownMenuItem(value: l.id, child: Text(l.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLockId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Access Code'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _generate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (_selectedLockId == null || _selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a property and lock')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(accessCodesProvider.notifier).generateCode(
            propertyId: _selectedPropertyId!,
            lockId: _selectedLockId!,
            code: _codeController.text,
            validFrom: _validFrom,
            validUntil: _validUntil,
            guestName: _guestNameController.text.isNotEmpty
                ? _guestNameController.text
                : null,
            guestEmail: _guestEmailController.text.isNotEmpty
                ? _guestEmailController.text
                : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
