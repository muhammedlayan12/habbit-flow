import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_client.dart';
import '../core/utils/date_utils.dart';
import '../models/routine.dart';

class RoutineProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  List<Routine> _routines = [];
  List<RoutineStep> _steps = [];
  List<RoutineCompletion> _completions = [];
  String? _userId;
  bool isLoading = true;
  String? error;

  List<Routine> get routines => List.unmodifiable(_routines);

  List<RoutineStep> stepsFor(String routineId) {
    final list = _steps.where((s) => s.routineId == routineId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final routineRows = await _client
          .from('routines')
          .select()
          .eq('user_id', userId)
          .order('start_time');
      _routines =
          (routineRows as List).map((r) => Routine.fromRow(r as Map<String, dynamic>)).toList();

      final routineIds = _routines.map((r) => r.id).toList();
      if (routineIds.isNotEmpty) {
        final stepRows =
            await _client.from('routine_steps').select().inFilter('routine_id', routineIds);
        _steps = (stepRows as List)
            .map((r) => RoutineStep.fromRow(r as Map<String, dynamic>))
            .toList();
      } else {
        _steps = [];
      }

      final completionRows =
          await _client.from('routine_completions').select().eq('user_id', userId);
      _completions = (completionRows as List)
          .map((r) => RoutineCompletion.fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('RoutineProvider.loadForUser failed: $e');
      error = 'Could not load routines. Pull to refresh to try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Routine> createRoutine({
    required String title,
    String description = '',
    int startHour = 7,
    int startMinute = 0,
    int colorIndex = 0,
    List<RoutineStep> steps = const [],
  }) async {
    final draft = Routine(
      id: '',
      userId: _userId!,
      title: title,
      description: description,
      startTime:
          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}:00',
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    final row = await _client.from('routines').insert(draft.toInsertRow()).select().single();
    final routine = Routine.fromRow(row);
    _routines.add(routine);
    _routines.sort((a, b) => a.startHour.compareTo(b.startHour));

    if (steps.isNotEmpty) {
      final stepRows = <Map<String, dynamic>>[];
      int order = 0;
      for (final s in steps) {
        stepRows.add(RoutineStep(
          id: '',
          routineId: routine.id,
          title: s.title,
          durationSeconds: s.durationSeconds,
          order: order++,
          notes: s.notes,
        ).toInsertRow());
      }
      final inserted = await _client.from('routine_steps').insert(stepRows).select();
      _steps.addAll(
          (inserted as List).map((r) => RoutineStep.fromRow(r as Map<String, dynamic>)));
    }

    notifyListeners();
    return routine;
  }

  Future<void> updateRoutine(Routine routine) async {
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index == -1) return;
    await _client.from('routines').update(routine.toInsertRow()).eq('id', routine.id);
    _routines[index] = routine;
    notifyListeners();
  }

  Future<void> deleteRoutine(String routineId) async {
    await _client.from('routines').delete().eq('id', routineId);
    _routines.removeWhere((r) => r.id == routineId);
    _steps.removeWhere((s) => s.routineId == routineId);
    _completions.removeWhere((c) => c.routineId == routineId);
    notifyListeners();
  }

  /// Replaces every step of [routineId] with [steps], re-numbering their
  /// `order`. Used both for manual edits and for drag-and-drop reordering.
  Future<void> replaceSteps(String routineId, List<RoutineStep> steps) async {
    await _client.from('routine_steps').delete().eq('routine_id', routineId);
    _steps.removeWhere((s) => s.routineId == routineId);

    if (steps.isEmpty) {
      notifyListeners();
      return;
    }
    final rows = <Map<String, dynamic>>[];
    int order = 0;
    for (final s in steps) {
      rows.add(s.copyWith(order: order++).toInsertRow());
    }
    final inserted = await _client.from('routine_steps').insert(rows).select();
    _steps.addAll((inserted as List).map((r) => RoutineStep.fromRow(r as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> addStep(String routineId, RoutineStep step) async {
    final currentMax = stepsFor(routineId).length;
    final row = await _client
        .from('routine_steps')
        .insert(step.copyWith(order: currentMax).toInsertRow())
        .select()
        .single();
    _steps.add(RoutineStep.fromRow(row));
    notifyListeners();
  }

  Future<void> updateStep(RoutineStep step) async {
    final index = _steps.indexWhere((s) => s.id == step.id);
    if (index == -1) return;
    await _client.from('routine_steps').update(step.toInsertRow()).eq('id', step.id);
    _steps[index] = step;
    notifyListeners();
  }

  Future<void> deleteStep(String stepId, String routineId) async {
    await _client.from('routine_steps').delete().eq('id', stepId);
    _steps.removeWhere((s) => s.id == stepId);
    final remaining = stepsFor(routineId);
    await replaceSteps(routineId, remaining);
  }

  Future<void> reorderSteps(String routineId, int oldIndex, int newIndex) async {
    final list = stepsFor(routineId);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await replaceSteps(routineId, list);
  }

  bool isCompletedOn(String routineId, DateTime date) {
    final d = AppDateUtils.dateOnly(date);
    return _completions
        .any((c) => c.routineId == routineId && AppDateUtils.isSameDay(c.date, d));
  }

  Future<void> markCompleted(String routineId, {DateTime? date}) async {
    final d = AppDateUtils.dateOnly(date ?? DateTime.now());
    if (isCompletedOn(routineId, d)) return;
    final row = await _client
        .from('routine_completions')
        .insert(RoutineCompletion.insertRow(routineId: routineId, userId: _userId!, date: d))
        .select()
        .single();
    _completions.add(RoutineCompletion.fromRow(row));
    notifyListeners();
  }

  int completionCountFor(String routineId) =>
      _completions.where((c) => c.routineId == routineId).length;

  int get totalCompletionsThisWeek {
    final weekStart = AppDateUtils.startOfWeek(DateTime.now());
    return _completions.where((c) => !c.date.isBefore(weekStart)).length;
  }
}
