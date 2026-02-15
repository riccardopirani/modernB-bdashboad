import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:lockflow/main.dart' show isSupabaseReady;

// Supabase client provider — returns null if not initialized
final supabaseProvider = Provider<SupabaseClient?>((ref) {
  if (!isSupabaseReady) return null;
  return Supabase.instance.client;
});

// Non-nullable convenience — throws clear error
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = ref.watch(supabaseProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not initialized. '
      'Set valid SUPABASE_URL and SUPABASE_ANON_KEY.',
    );
  }
  return client;
});

// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  if (supabase == null) return Stream.value(null);
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

// Current org provider
final currentOrgProvider = StateProvider<String?>((ref) => null);

// Auth notifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthNotifier(supabase);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient? _supabase;

  AuthNotifier(this._supabase) : super(const AsyncValue.data(null));

  Future<void> signUp(String email, String password, String fullName) async {
    if (_supabase == null) {
      state = AsyncValue.error(
          StateError('Supabase not initialized'), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      await _supabase!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    if (_supabase == null) {
      state = AsyncValue.error(
          StateError('Supabase not initialized'), StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      await _supabase!.auth.signInWithPassword(
          email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    if (_supabase == null) return;
    state = const AsyncValue.loading();
    try {
      await _supabase!.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
