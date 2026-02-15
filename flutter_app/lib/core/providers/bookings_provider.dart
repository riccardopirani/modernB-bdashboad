import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

class Booking {
  final String id;
  final String propertyId;
  final String icalUid;
  final String guestName;
  final String? guestEmail;
  final String? guestPhone;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final String? notes;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.propertyId,
    required this.icalUid,
    required this.guestName,
    this.guestEmail,
    this.guestPhone,
    required this.checkInDate,
    required this.checkOutDate,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      propertyId: json['property_id'],
      icalUid: json['ical_uid'],
      guestName: json['guest_name'],
      guestEmail: json['guest_email'],
      guestPhone: json['guest_phone'],
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUpcoming => checkInDate.isAfter(DateTime.now());
  bool get isOngoing =>
      checkInDate.isBefore(DateTime.now()) &&
      checkOutDate.isAfter(DateTime.now());
  bool get isCompleted => checkOutDate.isBefore(DateTime.now());
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<Booking>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final orgId = ref.watch(currentOrgProvider);

  return BookingsNotifier(supabase, orgId);
});

final upcomingBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookings = await ref.watch(bookingsProvider.future);
  return bookings.where((b) => b.isUpcoming).toList();
});

class BookingsNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final SupabaseClient _supabase;
  final String? _orgId;

  BookingsNotifier(this._supabase, this._orgId)
      : super(const AsyncValue.loading()) {
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (_orgId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('org_id', _orgId!)
          .order('check_in_date', ascending: true);

      final bookings = (response as List)
          .map((b) => Booking.fromJson(b as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(bookings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createBooking({
    required String propertyId,
    required String icalUid,
    required String guestName,
    String? guestEmail,
    String? guestPhone,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    String? checkInTime,
    String? checkOutTime,
    String status = 'confirmed',
    String? notes,
  }) async {
    if (_orgId == null) return;

    try {
      await _supabase.from('bookings').insert({
        'org_id': _orgId,
        'property_id': propertyId,
        'ical_uid': icalUid,
        'guest_name': guestName,
        'guest_email': guestEmail,
        'guest_phone': guestPhone,
        'check_in_date': checkInDate.toIso8601String().split('T')[0],
        'check_out_date': checkOutDate.toIso8601String().split('T')[0],
        'check_in_time': checkInTime,
        'check_out_time': checkOutTime,
        'status': status,
        'notes': notes,
      });

      await _loadBookings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      await _loadBookings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
