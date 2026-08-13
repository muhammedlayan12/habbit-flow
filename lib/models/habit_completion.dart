class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date; // date-only
  final int value;
  final DateTime completedAt;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    this.value = 1,
    required this.completedAt,
  });

  factory HabitCompletion.fromRow(Map<String, dynamic> row) {
    return HabitCompletion(
      id: row['id'] as String,
      habitId: row['habit_id'] as String,
      userId: row['user_id'] as String,
      date: DateTime.parse(row['completion_date'] as String),
      value: (row['value'] as int?) ?? 1,
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> insertRow({
    required String habitId,
    required String userId,
    required DateTime date,
    required int value,
  }) =>
      {
        'habit_id': habitId,
        'user_id': userId,
        'completion_date': date.toIso8601String().split('T').first,
        'value': value,
        'completed': true,
      };
}
