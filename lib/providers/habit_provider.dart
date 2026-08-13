import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_client.dart';
import '../core/utils/date_utils.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/notification_service.dart';

class HabitStats {
  final int currentStreak;
  final int bestStreak;
  final double completionRate; // 0..1 over the habit's lifetime
  final int totalCompletions;

  const HabitStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.totalCompletions,
  });
}

/// Owns all habit + habit-completion data for the signed-in user, backed
/// directly by Supabase (Postgres + RLS is the source of truth — nothing
/// is cached locally beyond the in-memory lists needed to render the UI).
///
/// Streak math is computed client-side from the real completion rows
/// returned by Supabase — never faked.
class HabitProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  String? _userId;
  bool isLoading = true;
  String? error;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<HabitCompletion> get completions => List.unmodifiable(_completions);

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final habitRows = await _client
          .from('habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _habits = (habitRows as List).map((r) => Habit.fromRow(r as Map<String, dynamic>)).toList();

      final completionRows =
          await _client.from('habit_completions').select().eq('user_id', userId);
      _completions = (completionRows as List)
          .map((r) => HabitCompletion.fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('HabitProvider.loadForUser failed: $e');
      error = 'Could not load habits. Pull to refresh to try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Habit> createHabit({
    required String title,
    String description = '',
    String category = 'General',
    required String iconKey,
    int colorIndex = 0,
    HabitFrequency frequency = const HabitFrequency(),
    String targetUnit = '1 time',
    int targetValue = 1,
    bool reminderEnabled = false,
    int? reminderHour,
    int? reminderMinute,
    DateTime? startDate,
  }) async {
    final draft = Habit(
      id: '',
      userId: _userId!,
      title: title,
      description: description,
      category: category,
      iconKey: iconKey,
      colorIndex: colorIndex,
      frequency: frequency,
      targetUnit: targetUnit,
      targetValue: targetValue,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderEnabled && reminderHour != null && reminderMinute != null
          ? '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}:00'
          : null,
      startDate: AppDateUtils.dateOnly(startDate ?? DateTime.now()),
      createdAt: DateTime.now(),
    );

    final row =
        await _client.from('habits').insert(draft.toInsertRow()).select().single();
    final habit = Habit.fromRow(row);
    _habits.insert(0, habit);

    if (reminderEnabled && reminderHour != null && reminderMinute != null) {
      await NotificationService.instance.scheduleDaily(
        id: 'habit_${habit.id}',
        title: 'Habit reminder',
        body: '${habit.title} — ${habit.targetUnit}',
        hour: reminderHour,
        minute: reminderMinute,
      );
    }
    notifyListeners();
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;
    await _client.from('habits').update(habit.toInsertRow()).eq('id', habit.id);
    _habits[index] = habit;

    await NotificationService.instance.cancel('habit_${habit.id}');
    if (habit.reminderEnabled && habit.reminderHour != null && habit.reminderMinute != null) {
      await NotificationService.instance.scheduleDaily(
        id: 'habit_${habit.id}',
        title: 'Habit reminder',
        body: '${habit.title} — ${habit.targetUnit}',
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    }
    notifyListeners();
  }

  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
    _habits.removeWhere((h) => h.id == habitId);
    _completions.removeWhere((c) => c.habitId == habitId);
    await NotificationService.instance.cancel('habit_$habitId');
    notifyListeners();
  }

  Future<void> togglePause(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;
    final updated = _habits[index].copyWith(isActive: !_habits[index].isActive);
    await _client.from('habits').update({'is_active': updated.isActive}).eq('id', habitId);
    _habits[index] = updated;
    notifyListeners();
  }

  bool isCompletedOn(String habitId, DateTime date) {
    final d = AppDateUtils.dateOnly(date);
    return _completions.any((c) => c.habitId == habitId && AppDateUtils.isSameDay(c.date, d));
  }

  /// Toggles completion for [habitId] on [date] (defaults to today).
  Future<void> toggleCompletion(String habitId, {DateTime? date}) async {
    final d = AppDateUtils.dateOnly(date ?? DateTime.now());
    final existingIndex = _completions.indexWhere(
      (c) => c.habitId == habitId && AppDateUtils.isSameDay(c.date, d),
    );

    try {
      if (existingIndex != -1) {
        final completion = _completions[existingIndex];
        await _client.from('habit_completions').delete().eq('id', completion.id);
        _completions.removeAt(existingIndex);
      } else {
        final habit = _habits.firstWhere((h) => h.id == habitId);
        final row = await _client
            .from('habit_completions')
            .insert(HabitCompletion.insertRow(
              habitId: habitId,
              userId: _userId!,
              date: d,
              value: habit.targetValue,
            ))
            .select()
            .single();
        _completions.add(HabitCompletion.fromRow(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('toggleCompletion failed: $e');
      notifyListeners();
    }
  }

  List<Habit> habitsScheduledFor(DateTime date) {
    return _habits
        .where((h) => h.isActive && !h.startDate.isAfter(AppDateUtils.dateOnly(date)))
        .where((h) => h.frequency.occursOn(date))
        .toList();
  }

  Set<DateTime> _completedDatesFor(String habitId) {
    return _completions
        .where((c) => c.habitId == habitId)
        .map((c) => AppDateUtils.dateOnly(c.date))
        .toSet();
  }

  /// Computes real streaks & completion rate for a habit from its actual
  /// completion history — never a placeholder value.
  HabitStats statsFor(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final completedDates = _completedDatesFor(habitId);
    final start = AppDateUtils.dateOnly(habit.startDate);
    final today = AppDateUtils.dateOnly(DateTime.now());

    int currentStreak = 0;
    DateTime cursor = today;
    if (habit.frequency.occursOn(cursor) && !completedDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int guard = 0;
    while (!cursor.isBefore(start) && guard < 3650) {
      guard++;
      if (habit.frequency.occursOn(cursor)) {
        if (completedDates.contains(cursor)) {
          currentStreak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else {
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    int bestStreak = 0;
    int running = 0;
    int scheduledCount = 0;
    int completedCount = 0;
    DateTime day = start;
    int guard2 = 0;
    while (!day.isAfter(today) && guard2 < 3650) {
      guard2++;
      if (habit.frequency.occursOn(day)) {
        scheduledCount++;
        if (completedDates.contains(day)) {
          completedCount++;
          running++;
          if (running > bestStreak) bestStreak = running;
        } else {
          running = 0;
        }
      }
      day = day.add(const Duration(days: 1));
    }

    final rate = scheduledCount == 0 ? 0.0 : completedCount / scheduledCount;

    return HabitStats(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completionRate: rate,
      totalCompletions: completedDates.length,
    );
  }

  Map<DateTime, double> weeklyCompletionRatio({DateTime? end}) {
    final days = AppDateUtils.lastNDays(7, end: end);
    final Map<DateTime, double> result = {};
    for (final day in days) {
      final scheduled = habitsScheduledFor(day);
      if (scheduled.isEmpty) {
        result[day] = 0;
        continue;
      }
      final completedCount = scheduled.where((h) => isCompletedOn(h.id, day)).length;
      result[day] = completedCount / scheduled.length;
    }
    return result;
  }

  int get totalActiveHabits => _habits.where((h) => h.isActive).length;
}
