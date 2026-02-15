import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockflow/core/config/theme.dart';
import 'package:lockflow/core/providers/billing_provider.dart';
import 'package:intl/intl.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text('Manage your subscription and billing',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),

            // Current Plan
            subscriptionAsync.when(
              loading: () => _buildSkeletonCard(isDark),
              error: (e, _) => Text('Error: $e'),
              data: (subscription) {
                if (subscription == null) {
                  return _buildNoPlan(context, ref, isDark);
                }
                return _buildCurrentPlan(context, ref, subscription, isDark);
              },
            ),
            const SizedBox(height: 32),

            // Pricing Cards
            Text('Available Plans',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth > 600
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _PricingCard(
                        plan: 'Basic',
                        price: 'Free',
                        period: '',
                        features: const [
                          'Up to 3 properties',
                          'Manual code generation',
                          'Basic dashboard',
                          'iCal sync (every 6h)',
                        ],
                        isDark: isDark,
                        isCurrent: subscriptionAsync.valueOrNull == null,
                        onSelect: null,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _PricingCard(
                        plan: 'Pro',
                        price: '\$29',
                        period: '/month',
                        features: const [
                          'Unlimited properties',
                          'Auto code generation',
                          'TTLock integration',
                          'iCal sync (every 15m)',
                          'Guest messaging',
                          'Priority support',
                        ],
                        isDark: isDark,
                        isPopular: true,
                        isCurrent: subscriptionAsync.valueOrNull?.planName == 'pro',
                        onSelect: () => _handleSubscribe(context, ref, 'pro'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _PricingCard(
                        plan: 'Enterprise',
                        price: '\$99',
                        period: '/month',
                        features: const [
                          'Everything in Pro',
                          'Multi-team support',
                          'Custom automations',
                          'API access',
                          'White-label options',
                          'Dedicated support',
                        ],
                        isDark: isDark,
                        isCurrent:
                            subscriptionAsync.valueOrNull?.planName == 'enterprise',
                        onSelect: () =>
                            _handleSubscribe(context, ref, 'enterprise'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlan(BuildContext context, WidgetRef ref,
      SubscriptionInfo sub, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: sub.isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
        boxShadow: isDark ? null : AppElevation.shadowSoft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child:
                const Icon(Icons.workspace_premium, size: 28, color: AppColors.accent),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${sub.planName[0].toUpperCase()}${sub.planName.substring(1)} Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: sub.isActive
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        sub.isCanceling
                            ? 'Canceling'
                            : sub.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              sub.isActive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sub.isCanceling
                      ? 'Expires ${DateFormat('MMM d, y').format(sub.currentPeriodEnd)}'
                      : 'Renews ${DateFormat('MMM d, y').format(sub.currentPeriodEnd)}',
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
          FilledButton(
            onPressed: () => _handleManageBilling(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              foregroundColor:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Manage Billing'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlan(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.info_outline, size: 28, color: AppColors.info),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upgrade to Pro to unlock TTLock integration and auto code generation',
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
          FilledButton(
            onPressed: () => _handleSubscribe(context, ref, 'pro'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }

  void _handleSubscribe(BuildContext context, WidgetRef ref, String plan) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating checkout session...')),
      );
      final url = await ref.read(subscriptionProvider.notifier).createCheckoutSession(
            plan: plan,
            successUrl: '${Uri.base}billing?success=true',
            cancelUrl: '${Uri.base}billing?canceled=true',
          );
      // In a real app, launch URL with url_launcher
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout URL: $url'), duration: const Duration(seconds: 10)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleManageBilling(BuildContext context, WidgetRef ref) async {
    try {
      final url = await ref.read(subscriptionProvider.notifier).createPortalSession(
            returnUrl: '${Uri.base}billing',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Portal URL: $url'), duration: const Duration(seconds: 10)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _PricingCard extends StatefulWidget {
  final String plan;
  final String price;
  final String period;
  final List<String> features;
  final bool isDark;
  final bool isPopular;
  final bool isCurrent;
  final VoidCallback? onSelect;

  const _PricingCard({
    required this.plan,
    required this.price,
    required this.period,
    required this.features,
    required this.isDark,
    this.isPopular = false,
    this.isCurrent = false,
    this.onSelect,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: widget.isPopular
                ? AppColors.accent
                : (widget.isDark ? AppColors.darkOutline : AppColors.outline),
            width: widget.isPopular ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? AppElevation.shadowLarge
              : (widget.isDark ? null : AppElevation.shadowSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isPopular)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              widget.plan,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.price,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                if (widget.period.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      widget.period,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ...widget.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: widget.isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Current Plan'),
                    )
                  : FilledButton(
                      onPressed: widget.onSelect,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.isPopular
                            ? AppColors.accent
                            : (widget.isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant),
                        foregroundColor: widget.isPopular
                            ? Colors.white
                            : (widget.isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                          widget.onSelect == null ? 'Current' : 'Get Started'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
