import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase connection details from the bundled `.env` file.
///
/// `.env` is loaded as a Flutter asset (see pubspec.yaml) rather than
/// compiled into source, so real projects can swap in their own file
/// without touching any Dart code. Only the public anon/publishable key
/// ever lives here — never the service_role key.
class EnvConfig {
  EnvConfig._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // No .env bundled — fall back to --dart-define values if provided.
    }
  }

  static String get supabaseUrl =>
      dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
