class Routine {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String routineType;
  final String startTime; // 'HH:mm:ss'
  final int colorIndex;
  final bool isActive;
  final DateTime createdAt;

  const Routine({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.routineType = 'General',
    this.startTime = '07:00:00',
    this.colorIndex = 0,
    this.isActive = true,
    required this.createdAt,
  });

  int get startHour => int.tryParse(startTime.split(':').first) ?? 7;
  int get startMinute => int.tryParse(startTime.split(':')[1]) ?? 0;

  Routine copyWith({
    String? title,
    String? description,
    String? routineType,
    String? startTime,
    int? colorIndex,
    bool? isActive,
  }) {
    return Routine(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      routineType: routineType ?? this.routineType,
      startTime: startTime ?? this.startTime,
      colorIndex: colorIndex ?? this.colorIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory Routine.fromRow(Map<String, dynamic> row) {
    return Routine(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      routineType: (row['routine_type'] as String?) ?? 'General',
      startTime: (row['start_time'] as String?) ?? '07:00:00',
      colorIndex: (row['color_index'] as int?) ?? 0,
      isActive: (row['is_active'] as bool?) ?? true,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertRow() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'routine_type': routineType,
        'start_time': startTime,
        'color_index': colorIndex,
        'is_active': isActive,
      };
}

class RoutineStep {
  final String id;
  final String routineId;
  final String title;
  final int durationSeconds;
  final int order;
  final String notes;

  const RoutineStep({
    required this.id,
    required this.routineId,
    required this.title,
    this.durationSeconds = 300,
    required this.order,
    this.notes = '',
  });

  RoutineStep copyWith({String? title, int? durationSeconds, int? order, String? notes}) {
    return RoutineStep(
      id: id,
      routineId: routineId,
      title: title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      order: order ?? this.order,
      notes: notes ?? this.notes,
    );
  }

  factory RoutineStep.fromRow(Map<String, dynamic> row) {
    return RoutineStep(
      id: row['id'] as String,
      routineId: row['routine_id'] as String,
      title: row['title'] as String,
      durationSeconds: (row['duration_seconds'] as int?) ?? 300,
      order: (row['step_order'] as int?) ?? 0,
      notes: (row['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toInsertRow() => {
        'routine_id': routineId,
        'title': title,
        'notes': notes,
        'duration_seconds': durationSeconds,
        'step_order': order,
      };
}

class RoutineCompletion {
  final String id;
  final String routineId;
  final String userId;
  final DateTime date;
  final DateTime completedAt;

  const RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.userId,
    required this.date,
    required this.completedAt,
  });

  factory RoutineCompletion.fromRow(Map<String, dynamic> row) {
    return RoutineCompletion(
      id: row['id'] as String,
      routineId: row['routine_id'] as String,
      userId: row['user_id'] as String,
      date: DateTime.parse(row['completion_date'] as String),
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> insertRow({
    required String routineId,
    required String userId,
    required DateTime date,
  }) =>
      {
        'routine_id': routineId,
        'user_id': userId,
        'completion_date': date.toIso8601String().split('T').first,
      };
}
