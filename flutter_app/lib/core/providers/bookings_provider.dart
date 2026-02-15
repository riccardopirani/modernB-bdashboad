import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
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

final upcomingBookingsProvider = Provider<AsyncValue<List<Booking>>>((ref) {
  final bookingsAsync = ref.watch(bookingsProvider);
  return bookingsAsync.whenData(
    (bookings) => bookings.where((b) => b.isUpcoming).toList(),
  );
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      await _loadBookings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
