import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'auth_provider.dart';

class TTLockIntegration {
  final String id;
  final String orgId;
  final String? ttlockUserId;
  final bool isActive;
  final DateTime? tokenExpiresAt;
  final DateTime createdAt;

  TTLockIntegration({
    required this.id,
    required this.orgId,
    this.ttlockUserId,
    required this.isActive,
    this.tokenExpiresAt,
    required this.createdAt,
  });

  factory TTLockIntegration.fromJson(Map<String, dynamic> json) {
    return TTLockIntegration(
      id: json['id'],
      orgId: json['org_id'],
      ttlockUserId: json['ttlock_user_id'],
      isActive: json['is_active'] ?? false,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isTokenExpired =>
      tokenExpiresAt != null && tokenExpiresAt!.isBefore(DateTime.now());
}

final ttlockIntegrationProvider =
    StateNotifierProvider<TTLockIntegrationNotifier, AsyncValue<TTLockIntegration?>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);
  return TTLockIntegrationNotifier(supabase, orgId);
});

class TTLockIntegrationNotifier extends StateNotifier<AsyncValue<TTLockIntegration?>> {
  final SupabaseClient? _supabase;
  final String? _orgId;

  TTLockIntegrationNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (_supabase == null || _orgId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final response = await _supabase!
          .from('integrations_ttlock')
          .select()
          .eq('org_id', _orgId!)
          .maybeSingle();
      if (response != null) {
        state = AsyncValue.data(TTLockIntegration.fromJson(response));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> startAuth() async {
    if (_supabase == null) throw Exception('Supabase not initialized');
    if (_orgId == null) throw Exception('No organization selected');
    final res = await _supabase!.functions.invoke(
      'ttlock-auth-start',
      body: {'org_id': _orgId},
    );
    final data = res.data as Map<String, dynamic>;
    return data['authorization_url'] as String;
  }

  Future<void> completeAuth(String code, String state) async {
    if (_supabase == null) throw Exception('Supabase not initialized');
    if (_orgId == null) throw Exception('No organization selected');
    await _supabase!.functions.invoke(
      'ttlock-auth-callback',
      body: {'code': code, 'state': state, 'org_id': _orgId},
    );
    await _load();
  }

  Future<void> syncLocks() async {
    if (_supabase == null) throw Exception('Supabase not initialized');
    if (_orgId == null) throw Exception('No organization selected');
    await _supabase!.functions.invoke(
      'ttlock-sync-locks',
      body: {'org_id': _orgId},
    );
  }

  Future<void> disconnect() async {
    if (_supabase == null || _orgId == null) return;
    await _supabase!
        .from('integrations_ttlock')
        .update({'is_active': false})
        .eq('org_id', _orgId!);
    await _load();
  }
}
