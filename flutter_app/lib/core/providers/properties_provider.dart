import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'auth_provider.dart';

class Property {
  final String id;
  final String orgId;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String? imageUrl;
  final String? icalUrl;
  final DateTime? icalLastSyncedAt;
  final String? icalSyncStatus;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.orgId,
    required this.name,
    this.address,
    this.city,
    this.country,
    this.imageUrl,
    this.icalUrl,
    this.icalLastSyncedAt,
    this.icalSyncStatus,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      orgId: json['org_id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      imageUrl: json['image_url'],
      icalUrl: json['ical_url'],
      icalLastSyncedAt: json['ical_last_synced_at'] != null
          ? DateTime.parse(json['ical_last_synced_at'])
          : null,
      icalSyncStatus: json['ical_sync_status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<Property>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);
  return PropertiesNotifier(supabase, orgId);
});

class PropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final SupabaseClient? _supabase;
  final String? _orgId;

  PropertiesNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    if (_supabase == null || _orgId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _supabase!
          .from('properties')
          .select()
          .eq('org_id', _orgId!)
          .order('created_at', ascending: false);
      final properties = (response as List)
          .map((p) => Property.fromJson(p as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(properties);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProperty({
    required String name,
    String? address,
    String? city,
    String? country,
    String? icalUrl,
  }) async {
    if (_supabase == null || _orgId == null) return;
    try {
      final response = await _supabase!
          .from('properties')
          .insert({
            'org_id': _orgId,
            'name': name,
            'address': address,
            'city': city,
            'country': country,
            'ical_url': icalUrl,
          })
          .select();

      if (response.isNotEmpty) {
        final newProperty = Property.fromJson(response[0]);
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data([newProperty, ...current]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    if (_supabase == null) return;
    try {
      await _supabase!.from('properties').delete().eq('id', propertyId);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
          current.where((p) => p.id != propertyId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => _loadProperties();
}
