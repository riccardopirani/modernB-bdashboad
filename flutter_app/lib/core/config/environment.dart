import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get supabaseUrlFromEnv =>
      dotenv.env['SUPABASE_URL'] ?? supabaseUrl;

  static String get supabaseAnonKeyFromEnv =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;

  static String get stripePublishableKeyFromEnv =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? stripePublishableKey;
}
