import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_client.dart';
import '../core/utils/date_utils.dart';
import '../models/focus_session.dart';
import '../services/notification_service.dart';

enum FocusTimerStatus { idle, running, paused, finished }

class FocusProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  List<FocusSession> _sessions = [];
  String? _userId;

  FocusTimerStatus timerStatus = FocusTimerStatus.idle;
  int totalSeconds = 25 * 60;
  int remainingSeconds = 25 * 60;
  Timer? _ticker;
  DateTime? _startedAt;
  String? _label;

  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    try {
      final rows = await _client
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);
      _sessions =
          (rows as List).map((r) => FocusSession.fromRow(r as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('FocusProvider.loadForUser failed: $e');
    }
    notifyListeners();
  }

  void configure(int minutes) {
    if (timerStatus == FocusTimerStatus.running) return;
    totalSeconds = minutes * 60;
    remainingSeconds = totalSeconds;
    timerStatus = FocusTimerStatus.idle;
    notifyListeners();
  }

  void start({String? label}) {
    _startedAt = DateTime.now();
    _label = label;
    timerStatus = FocusTimerStatus.running;
    notifyListeners();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (timerStatus != FocusTimerStatus.running) return;
    timerStatus = FocusTimerStatus.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (timerStatus != FocusTimerStatus.paused) return;
    timerStatus = FocusTimerStatus.running;
    notifyListeners();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void reset() {
    _ticker?.cancel();
    remainingSeconds = totalSeconds;
    timerStatus = FocusTimerStatus.idle;
    _startedAt = null;
    notifyListeners();
  }

  void _tick() {
    if (remainingSeconds <= 1) {
      remainingSeconds = 0;
      _completeSession(finishedNaturally: true);
      return;
    }
    remainingSeconds--;
    notifyListeners();
  }

  Future<void> finishEarly() async {
    await _completeSession(finishedNaturally: false);
  }

  Future<void> _completeSession({required bool finishedNaturally}) async {
    _ticker?.cancel();
    timerStatus = FocusTimerStatus.finished;
    final startedAt = _startedAt;
    if (startedAt != null && _userId != null) {
      try {
        final elapsedSeconds = totalSeconds - remainingSeconds;
        final row = await _client
            .from('focus_sessions')
            .insert(FocusSession.insertRow(
              userId: _userId!,
              durationSeconds: finishedNaturally ? totalSeconds : elapsedSeconds,
              completed: finishedNaturally,
              startedAt: startedAt,
              completedAt: DateTime.now(),
              label: _label,
            ))
            .select()
            .single();
        _sessions.insert(0, FocusSession.fromRow(row));
        if (finishedNaturally) {
          await NotificationService.instance.showNow(
            id: 'focus_${row['id']}',
            title: 'Focus Session Complete',
            body: 'Great job! You focused for ${totalSeconds ~/ 60} minutes.',
          );
        }
      } catch (e) {
        debugPrint('Failed to save focus session: $e');
      }
    }
    notifyListeners();
  }

  int get completedSessionsCount => _sessions.where((s) => s.completed).length;

  int get totalFocusMinutesThisWeek {
    final weekStart = AppDateUtils.startOfWeek(DateTime.now());
    return _sessions
        .where((s) => s.completed && !s.startedAt.isBefore(weekStart))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
