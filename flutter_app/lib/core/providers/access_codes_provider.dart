import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'auth_provider.dart';

class AccessCode {
  final String id;
  final String propertyId;
  final String lockId;
  final String? bookingId;
  final String? guestName;
  final String? guestEmail;
  final String? guestPhone;
  final String code;
  final String? ttlockCodeId;
  final DateTime validFrom;
  final DateTime validUntil;
  final int timesUsed;
  final int? maxUses;
  final String status;
  final String? sentVia;
  final DateTime? sentAt;
  final DateTime createdAt;

  AccessCode({
    required this.id,
    required this.propertyId,
    required this.lockId,
    this.bookingId,
    this.guestName,
    this.guestEmail,
    this.guestPhone,
    required this.code,
    this.ttlockCodeId,
    required this.validFrom,
    required this.validUntil,
    required this.timesUsed,
    this.maxUses,
    required this.status,
    this.sentVia,
    this.sentAt,
    required this.createdAt,
  });

  factory AccessCode.fromJson(Map<String, dynamic> json) {
    return AccessCode(
      id: json['id'],
      propertyId: json['property_id'],
      lockId: json['lock_id'],
      bookingId: json['booking_id'],
      guestName: json['guest_name'],
      guestEmail: json['guest_email'],
      guestPhone: json['guest_phone'],
      code: json['code'],
      ttlockCodeId: json['ttlock_code_id']?.toString(),
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: DateTime.parse(json['valid_until']),
      timesUsed: json['times_used'] ?? 0,
      maxUses: json['max_uses'],
      status: json['status'],
      sentVia: json['sent_via'],
      sentAt:
          json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isActive =>
      status == 'active' && DateTime.now().isBefore(validUntil);
  bool get isExpired => DateTime.now().isAfter(validUntil);
}

final accessCodesProvider = StateNotifierProvider<AccessCodesNotifier,
    AsyncValue<List<AccessCode>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);
  return AccessCodesNotifier(supabase, orgId);
});

class AccessCodesNotifier
    extends StateNotifier<AsyncValue<List<AccessCode>>> {
  final SupabaseClient _supabase;
  final String? _orgId;

  AccessCodesNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    if (_orgId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _supabase
          .from('access_codes')
          .select()
          .eq('org_id', _orgId!)
          .order('created_at', ascending: false);
      final codes = (response as List)
          .map((c) => AccessCode.fromJson(c as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(codes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateCode({
    required String propertyId,
    required String lockId,
    required String code,
    required DateTime validFrom,
    required DateTime validUntil,
    String? bookingId,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
  }) async {
    if (_orgId == null) return;
    try {
      final insertResponse = await _supabase
          .from('access_codes')
          .insert({
            'org_id': _orgId,
            'property_id': propertyId,
            'lock_id': lockId,
            'booking_id': bookingId,
            'guest_name': guestName,
            'guest_email': guestEmail,
            'guest_phone': guestPhone,
            'code': code,
            'valid_from': validFrom.toIso8601String(),
            'valid_until': validUntil.toIso8601String(),
            'status': 'active',
          })
          .select()
          .single();

      final accessCodeId = insertResponse['id'];
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.functions.invoke(
          'ttlock-generate-code',
          body: {
            'lock_id': lockId,
            'access_code_id': accessCodeId,
            'code': code,
            'valid_from': (validFrom.millisecondsSinceEpoch ~/ 1000),
            'valid_until': (validUntil.millisecondsSinceEpoch ~/ 1000),
            'org_id': _orgId,
          },
        );
      }
      await _loadCodes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> revokeCode(String codeId) async {
    try {
      await _supabase
          .from('access_codes')
          .update({'status': 'revoked'})
          .eq('id', codeId);
      await _loadCodes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendCode(String codeId, String via) async {
    try {
      await _supabase
          .from('access_codes')
          .update({
            'sent_via': via,
            'sent_at': DateTime.now().toIso8601String(),
          })
          .eq('id', codeId);
      await _loadCodes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
