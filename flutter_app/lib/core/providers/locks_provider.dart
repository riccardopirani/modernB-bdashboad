import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'auth_provider.dart';

class Lock {
  final String id;
  final String? propertyId;
  final String ttlockLockId;
  final String ttlockClientId;
  final String name;
  final String? model;
  final int? featureValue;
  final int status;
  final int? electricQuantity;
  final DateTime createdAt;

  Lock({
    required this.id,
    this.propertyId,
    required this.ttlockLockId,
    required this.ttlockClientId,
    required this.name,
    this.model,
    this.featureValue,
    required this.status,
    this.electricQuantity,
    required this.createdAt,
  });

  factory Lock.fromJson(Map<String, dynamic> json) {
    return Lock(
      id: json['id'],
      propertyId: json['property_id'],
      ttlockLockId: json['ttlock_lock_id'].toString(),
      ttlockClientId: json['ttlock_client_id'],
      name: json['name'],
      model: json['model'],
      featureValue: json['feature_value'],
      status: json['status'] ?? 0,
      electricQuantity: json['electric_quantity'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isLocked => status == 0;
  String get batteryStatus {
    if (electricQuantity == null || electricQuantity == -1) return 'Unknown';
    if (electricQuantity! < 20) return 'Low';
    if (electricQuantity! < 50) return 'Medium';
    return 'Good';
  }
}

final locksProvider =
    StateNotifierProvider<LocksNotifier, AsyncValue<List<Lock>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);
  return LocksNotifier(supabase, orgId);
});

class LocksNotifier extends StateNotifier<AsyncValue<List<Lock>>> {
  final SupabaseClient _supabase;
  final String? _orgId;

  LocksNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _loadLocks();
  }

  Future<void> _loadLocks() async {
    if (_orgId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _supabase
          .from('locks')
          .select()
          .eq('org_id', _orgId!)
          .order('created_at', ascending: false);
      final locks = (response as List)
          .map((l) => Lock.fromJson(l as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(locks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncLocks() async {
    if (_orgId == null) return;
    try {
      await _supabase.functions.invoke(
        'ttlock-sync-locks',
        body: {'org_id': _orgId},
      );
      await _loadLocks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> assignLockToProperty(String lockId, String propertyId) async {
    try {
      await _supabase
          .from('locks')
          .update({'property_id': propertyId})
          .eq('id', lockId);
      await _loadLocks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unassignLock(String lockId) async {
    try {
      await _supabase
          .from('locks')
          .update({'property_id': null})
          .eq('id', lockId);
      await _loadLocks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
