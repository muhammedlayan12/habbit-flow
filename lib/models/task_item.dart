enum TaskPriority { low, medium, high }

TaskPriority priorityFromString(String? value) {
  switch (value) {
    case 'high':
      return TaskPriority.high;
    case 'low':
      return TaskPriority.low;
    default:
      return TaskPriority.medium;
  }
}

class TaskItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskPriority priority;
  final String category;
  final DateTime? dueDate;
  final String? dueTime; // 'HH:mm:ss'
  final bool completed;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.category = 'General',
    this.dueDate,
    this.dueTime,
    this.completed = false,
    this.reminderEnabled = false,
    required this.createdAt,
    this.completedAt,
  });

  int? get dueHour => dueTime != null ? int.tryParse(dueTime!.split(':').first) : null;
  int? get dueMinute => dueTime != null ? int.tryParse(dueTime!.split(':')[1]) : null;

  TaskItem copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? dueTime,
    bool? completed,
    bool? reminderEnabled,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTime: dueTime ?? this.dueTime,
      completed: completed ?? this.completed,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  factory TaskItem.fromRow(Map<String, dynamic> row) {
    return TaskItem(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      priority: priorityFromString(row['priority'] as String?),
      category: (row['category'] as String?) ?? 'General',
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null,
      dueTime: row['due_time'] as String?,
      completed: (row['completed'] as bool?) ?? false,
      reminderEnabled: (row['reminder_enabled'] as bool?) ?? false,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      completedAt:
          row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertRow() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'category': category,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'due_time': dueTime,
        'completed': completed,
        'reminder_enabled': reminderEnabled,
        'completed_at': completedAt?.toIso8601String(),
      };
}
