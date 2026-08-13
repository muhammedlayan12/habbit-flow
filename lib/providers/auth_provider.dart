import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_client.dart';
import '../models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthResult {
  final bool success;
  final String? error;
  const AuthResult({required this.success, this.error});
}

/// Handles the full authentication lifecycle against Supabase Auth, plus
/// loading/updating the matching `profiles` and `user_preferences` rows.
///
/// A profile row is created automatically by a Postgres trigger the moment
/// a new `auth.users` row appears (see supabase_schema.sql), so this class
/// never has to insert a profile itself on signup — it just waits for it
/// and then reads it back.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  UserPreferences preferences = const UserPreferences();
  String? lastError;
  bool isLoading = false;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<void> bootstrap() async {
    _client.auth.onAuthStateChange.listen((data) {
      // Keep local state roughly aligned with Supabase's own session
      // lifecycle (e.g. token refresh failures, remote sign-out).
      if (data.event == AuthChangeEvent.signedOut && status == AuthStatus.authenticated) {
        currentUser = null;
        status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    final session = _client.auth.currentSession;
    if (session == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    await _loadProfile(session.user.id);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (row == null) {
        // Trigger hasn't created the row yet (rare race right after
        // signup) — retry briefly before giving up.
        await Future.delayed(const Duration(milliseconds: 700));
        final retry = await _client.from('profiles').select().eq('id', userId).maybeSingle();
        if (retry == null) {
          status = AuthStatus.unauthenticated;
          lastError = 'Could not load your profile. Please try again.';
          notifyListeners();
          return;
        }
        currentUser = AppUser.fromRow(retry);
      } else {
        currentUser = AppUser.fromRow(row);
      }

      await _loadPreferences(userId);

      if (currentUser!.isActive) {
        status = AuthStatus.authenticated;
      } else {
        status = AuthStatus.unauthenticated;
        lastError = 'This account has been deactivated. Contact support.';
        await _client.auth.signOut();
        currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      status = AuthStatus.unauthenticated;
      lastError = 'Could not connect to the server.';
      notifyListeners();
    }
  }

  Future<void> _loadPreferences(String userId) async {
    try {
      final row =
          await _client.from('user_preferences').select().eq('user_id', userId).maybeSingle();
      if (row != null) {
        preferences = UserPreferences.fromRow(row);
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    }
  }

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
      );
      final user = response.user;
      if (user == null) {
        lastError = 'Signup failed. Please try again.';
        isLoading = false;
        notifyListeners();
        return AuthResult(success: false, error: lastError);
      }

      // If email confirmation is required, there will be no session yet.
      if (response.session == null) {
        isLoading = false;
        lastError =
            'Account created. Please check your email to confirm before logging in.';
        notifyListeners();
        return AuthResult(success: false, error: lastError);
      }

      await _loadProfile(user.id);
      isLoading = false;
      notifyListeners();
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      isLoading = false;
      lastError = e.message;
      notifyListeners();
      return AuthResult(success: false, error: lastError);
    } catch (e) {
      isLoading = false;
      lastError = 'Something went wrong. Please try again.';
      notifyListeners();
      return AuthResult(success: false, error: lastError);
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final response =
          await _client.auth.signInWithPassword(email: email.trim(), password: password);
      final user = response.user;
      if (user == null) {
        isLoading = false;
        lastError = 'Invalid email or password.';
        notifyListeners();
        return AuthResult(success: false, error: lastError);
      }
      await _loadProfile(user.id);
      isLoading = false;
      notifyListeners();
      if (status != AuthStatus.authenticated) {
        return AuthResult(success: false, error: lastError ?? 'Login failed.');
      }
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      isLoading = false;
      lastError = e.message;
      notifyListeners();
      return AuthResult(success: false, error: lastError);
    } catch (e) {
      isLoading = false;
      lastError = 'Could not connect to the server.';
      notifyListeners();
      return AuthResult(success: false, error: lastError);
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    isLoading = true;
    notifyListeners();
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      isLoading = false;
      notifyListeners();
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      isLoading = false;
      lastError = e.message;
      notifyListeners();
      return AuthResult(success: false, error: lastError);
    } catch (e) {
      isLoading = false;
      lastError = 'Could not send reset email.';
      notifyListeners();
      return AuthResult(success: false, error: lastError);
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    currentUser = null;
    preferences = const UserPreferences();
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? productivityGoal,
    String? wakeUpTime,
    String? sleepTime,
    String? workStartTime,
    String? workEndTime,
    bool? onboardingComplete,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (productivityGoal != null) updates['productivity_goal'] = productivityGoal;
    if (wakeUpTime != null) updates['wake_up_time'] = wakeUpTime;
    if (sleepTime != null) updates['sleep_time'] = sleepTime;
    if (workStartTime != null) updates['work_start_time'] = workStartTime;
    if (workEndTime != null) updates['work_end_time'] = workEndTime;
    if (onboardingComplete != null) updates['onboarding_complete'] = onboardingComplete;
    if (updates.isEmpty) return;

    await _client.from('profiles').update(updates).eq('id', user.id);
    currentUser = user.copyWith(
      fullName: fullName,
      avatarUrl: avatarUrl,
      productivityGoal: productivityGoal,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
      workStartTime: workStartTime,
      workEndTime: workEndTime,
      onboardingComplete: onboardingComplete,
    );
    notifyListeners();
  }

  Future<void> completeOnboarding({
    String? mainGoal,
    String? wakeUpTime,
    String? sleepTime,
    String? workHours,
  }) async {
    await updateProfile(
      productivityGoal: mainGoal,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
      workStartTime: workHours,
      onboardingComplete: true,
    );
  }

  Future<AuthResult> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return const AuthResult(success: false, error: 'Could not update password.');
    }
  }

  Future<void> updatePreferences(UserPreferences updated) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('user_preferences').update(updated.toRow()).eq('user_id', user.id);
    preferences = updated;
    notifyListeners();
  }

  // ---------------- Admin operations ----------------

  Future<List<AppUser>> fetchAllUsers() async {
    final rows = await _client.from('profiles').select().order('created_at', ascending: false);
    return (rows as List).map((r) => AppUser.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<void> setUserActive(String userId, bool active) async {
    await _client.from('profiles').update({'is_active': active}).eq('id', userId);
    if (currentUser?.id == userId) {
      currentUser = currentUser!.copyWith(isActive: active);
    }
    notifyListeners();
  }
}
