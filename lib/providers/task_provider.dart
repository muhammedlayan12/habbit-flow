import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_client.dart';
import '../core/utils/date_utils.dart';
import '../models/task_item.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  List<TaskItem> _tasks = [];
  String? _userId;
  bool isLoading = true;
  String? error;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  List<TaskItem> get todayTasks {
    final today = AppDateUtils.dateOnly(DateTime.now());
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return AppDateUtils.isSameDay(t.dueDate!, today) && !t.completed;
    }).toList()
      ..sort(_byPriorityThenTime);
  }

  List<TaskItem> get upcomingTasks {
    final today = AppDateUtils.dateOnly(DateTime.now());
    return _tasks.where((t) {
      if (t.completed) return false;
      if (t.dueDate == null) return true;
      return AppDateUtils.dateOnly(t.dueDate!).isAfter(today);
    }).toList()
      ..sort(_byPriorityThenTime);
  }

  List<TaskItem> get completedTasks {
    final list = _tasks.where((t) => t.completed).toList();
    list.sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    return list;
  }

  int _byPriorityThenTime(TaskItem a, TaskItem b) {
    const order = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
    final p = order[a.priority]!.compareTo(order[b.priority]!);
    if (p != 0) return p;
    final aMinutes = (a.dueHour ?? 23) * 60 + (a.dueMinute ?? 59);
    final bMinutes = (b.dueHour ?? 23) * 60 + (b.dueMinute ?? 59);
    return aMinutes.compareTo(bMinutes);
  }

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final rows = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _tasks = (rows as List).map((r) => TaskItem.fromRow(r as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('TaskProvider.loadForUser failed: $e');
      error = 'Could not load tasks. Pull to refresh to try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<TaskItem> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    String category = 'General',
    DateTime? dueDate,
    int? dueHour,
    int? dueMinute,
    bool reminderEnabled = false,
  }) async {
    final draft = TaskItem(
      id: '',
      userId: _userId!,
      title: title,
      description: description,
      priority: priority,
      category: category,
      dueDate: dueDate != null ? AppDateUtils.dateOnly(dueDate) : null,
      dueTime: dueHour != null && dueMinute != null
          ? '${dueHour.toString().padLeft(2, '0')}:${dueMinute.toString().padLeft(2, '0')}:00'
          : null,
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
    );
    final row = await _client.from('tasks').insert(draft.toInsertRow()).select().single();
    final task = TaskItem.fromRow(row);
    _tasks.insert(0, task);

    if (reminderEnabled && dueDate != null && dueHour != null && dueMinute != null) {
      final reminderTime = DateTime(dueDate.year, dueDate.month, dueDate.day, dueHour, dueMinute);
      await NotificationService.instance.scheduleOneOff(
        id: 'task_${task.id}',
        title: 'Task due: ${task.title}',
        body: task.description.isEmpty ? 'Tap to review your task.' : task.description,
        dateTime: reminderTime,
      );
    }
    notifyListeners();
    return task;
  }

  Future<void> updateTask(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    await _client.from('tasks').update(task.toInsertRow()).eq('id', task.id);
    _tasks[index] = task;

    await NotificationService.instance.cancel('task_${task.id}');
    if (task.reminderEnabled &&
        task.dueDate != null &&
        task.dueHour != null &&
        task.dueMinute != null &&
        !task.completed) {
      final reminderTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.dueHour!,
        task.dueMinute!,
      );
      await NotificationService.instance.scheduleOneOff(
        id: 'task_${task.id}',
        title: 'Task due: ${task.title}',
        body: task.description.isEmpty ? 'Tap to review your task.' : task.description,
        dateTime: reminderTime,
      );
    }
    notifyListeners();
  }

  Future<void> toggleComplete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    final completed = !task.completed;
    final updated = task.copyWith(
      completed: completed,
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
    );
    await _client.from('tasks').update({
      'completed': completed,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    }).eq('id', taskId);
    _tasks[index] = updated;
    if (completed) {
      await NotificationService.instance.cancel('task_${task.id}');
    }
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    await NotificationService.instance.cancel('task_$taskId');
    notifyListeners();
  }

  Future<void> reschedule(String taskId, DateTime newDate) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final d = AppDateUtils.dateOnly(newDate);
    await _client
        .from('tasks')
        .update({'due_date': d.toIso8601String().split('T').first}).eq('id', taskId);
    _tasks[index] = _tasks[index].copyWith(dueDate: d);
    notifyListeners();
  }

  List<TaskItem> tasksDueOn(DateTime date) {
    return _tasks
        .where((t) => t.dueDate != null && AppDateUtils.isSameDay(t.dueDate!, date))
        .toList();
  }

  int get completedThisWeekCount {
    final weekStart = AppDateUtils.startOfWeek(DateTime.now());
    return _tasks
        .where((t) =>
            t.completed && t.completedAt != null && !t.completedAt!.isBefore(weekStart))
        .length;
  }
}
