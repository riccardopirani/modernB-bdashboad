import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'auth_provider.dart';

class SubscriptionInfo {
  final String id;
  final String orgId;
  final String stripeSubscriptionId;
  final String stripeCustomerId;
  final String status;
  final String planName;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? canceledAt;

  SubscriptionInfo({
    required this.id,
    required this.orgId,
    required this.stripeSubscriptionId,
    required this.stripeCustomerId,
    required this.status,
    required this.planName,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.canceledAt,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      id: json['id'],
      orgId: json['org_id'],
      stripeSubscriptionId: json['stripe_subscription_id'],
      stripeCustomerId: json['stripe_customer_id'],
      status: json['status'],
      planName: json['plan_name'] ?? 'basic',
      currentPeriodStart: DateTime.parse(json['current_period_start']),
      currentPeriodEnd: DateTime.parse(json['current_period_end']),
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
      canceledAt: json['canceled_at'] != null ? DateTime.parse(json['canceled_at']) : null,
    );
  }

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isCanceling => cancelAtPeriodEnd && isActive;
  int get daysRemaining => currentPeriodEnd.difference(DateTime.now()).inDays;
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionInfo?>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);
  return SubscriptionNotifier(supabase, orgId);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionInfo?>> {
  final SupabaseClient _supabase;
  final String? _orgId;

  SubscriptionNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (_orgId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final response = await _supabase
          .from('stripe_subscriptions')
          .select()
          .eq('org_id', _orgId!)
          .maybeSingle();
      if (response != null) {
        state = AsyncValue.data(SubscriptionInfo.fromJson(response));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> createCheckoutSession({
    required String plan,
    required String successUrl,
    required String cancelUrl,
  }) async {
    if (_orgId == null) throw Exception('No organization selected');
    final res = await _supabase.functions.invoke(
      'stripe-create-checkout',
      body: {
        'org_id': _orgId,
        'plan': plan,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return data['checkout_url'] as String;
  }

  Future<String> createPortalSession({required String returnUrl}) async {
    if (_orgId == null) throw Exception('No organization selected');
    final res = await _supabase.functions.invoke(
      'stripe-create-portal',
      body: {'org_id': _orgId, 'return_url': returnUrl},
    );
    final data = res.data as Map<String, dynamic>;
    return data['portal_url'] as String;
  }

  Future<void> refresh() async => _load();
}
