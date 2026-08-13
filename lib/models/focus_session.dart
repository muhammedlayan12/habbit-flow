class FocusSession {
  final String id;
  final String userId;
  final int durationSeconds;
  final bool completed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? label;

  const FocusSession({
    required this.id,
    required this.userId,
    required this.durationSeconds,
    this.completed = false,
    required this.startedAt,
    this.completedAt,
    this.label,
  });

  int get durationMinutes => (durationSeconds / 60).round();

  factory FocusSession.fromRow(Map<String, dynamic> row) {
    return FocusSession(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      durationSeconds: (row['duration_seconds'] as int?) ?? 0,
      completed: (row['completed'] as bool?) ?? false,
      startedAt: row['started_at'] != null
          ? DateTime.parse(row['started_at'] as String)
          : DateTime.now(),
      completedAt:
          row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
      label: row['label'] as String?,
    );
  }

  static Map<String, dynamic> insertRow({
    required String userId,
    required int durationSeconds,
    required bool completed,
    required DateTime startedAt,
    DateTime? completedAt,
    String? label,
  }) =>
      {
        'user_id': userId,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'label': label,
      };
}
