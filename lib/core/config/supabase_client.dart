import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_config.dart';

/// Initializes the Supabase SDK once at app startup and exposes the
/// shared client via [SupabaseService.client].
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    if (!EnvConfig.isConfigured) {
      debugPrint(
        'Supabase is not configured — check that .env contains SUPABASE_URL '
        'and SUPABASE_ANON_KEY.',
      );
      return;
    }
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
