import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hdjtmmwtgiinkmqaekcn.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_HG6uras00GxE1V3sH0tenQ_BpCRqWG5',
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
