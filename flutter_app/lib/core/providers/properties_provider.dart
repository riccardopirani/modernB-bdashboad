import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

// Models
class Property {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? icalUrl;
  final DateTime? icalLastSyncedAt;
  final String icalSyncStatus;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.icalUrl,
    this.icalLastSyncedAt,
    this.icalSyncStatus = 'idle',
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      icalUrl: json['ical_url'],
      icalLastSyncedAt: json['ical_last_synced_at'] != null
          ? DateTime.parse(json['ical_last_synced_at'])
          : null,
      icalSyncStatus: json['ical_sync_status'] ?? 'idle',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Properties notifier
final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<Property>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);

  return PropertiesNotifier(supabase, orgId);
});

class PropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final SupabaseClient _supabase;
  final String? _orgId;

  PropertiesNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    if (_orgId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('org_id', _orgId!)
          .order('created_at', ascending: false);

      final properties = (response as List)
          .map((p) => Property.fromJson(p as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(properties);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createProperty(String name, String? address, String? city,
      String? state, String? icalUrl) async {
    if (_orgId == null) return;

    try {
      final response = await _supabase.from('properties').insert({
        'org_id': _orgId,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'ical_url': icalUrl,
      }).select();

      if (response.isNotEmpty) {
        final newProperty = Property.fromJson(response[0]);
        state.whenData((properties) {
          state = AsyncValue.data([newProperty, ...properties]);
        });
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProperty(String id, {
    String? name,
    String? address,
    String? city,
    String? state,
    String? icalUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (icalUrl != null) updates['ical_url'] = icalUrl;

      await _supabase
          .from('properties')
          .update(updates)
          .eq('id', id);

      await _loadProperties();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await _supabase.from('properties').delete().eq('id', id);
      await _loadProperties();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> syncIcalBookings(String propertyId) async {
    if (_orgId == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase.functions.invoke(
        'ical-sync',
        body: {
          'property_id': propertyId,
          'org_id': _orgId,
        },
      );

      await _loadProperties();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
