import 'package:flutter/material.dart';

enum HabitFrequencyType { daily, weekdays, weekends, custom }

HabitFrequencyType frequencyTypeFromString(String? value) {
  switch (value) {
    case 'weekdays':
      return HabitFrequencyType.weekdays;
    case 'weekends':
      return HabitFrequencyType.weekends;
    case 'custom':
      return HabitFrequencyType.custom;
    default:
      return HabitFrequencyType.daily;
  }
}

class HabitFrequency {
  final HabitFrequencyType type;
  /// 1 = Monday ... 7 = Sunday. Only used when [type] is custom.
  final List<int> customDays;

  const HabitFrequency({
    this.type = HabitFrequencyType.daily,
    this.customDays = const [],
  });

  bool occursOn(DateTime date) {
    switch (type) {
      case HabitFrequencyType.daily:
        return true;
      case HabitFrequencyType.weekdays:
        return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
      case HabitFrequencyType.weekends:
        return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      case HabitFrequencyType.custom:
        return customDays.contains(date.weekday);
    }
  }

  String get label {
    switch (type) {
      case HabitFrequencyType.daily:
        return 'Every day';
      case HabitFrequencyType.weekdays:
        return 'Weekdays';
      case HabitFrequencyType.weekends:
        return 'Weekends';
      case HabitFrequencyType.custom:
        const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final sorted = [...customDays]..sort();
        return sorted.map((d) => names[d]).join(', ');
    }
  }
}

/// Curated icon set. Habits store the string [key] in Supabase (a `text`
/// column), which is looked up against this map on the client — far more
/// portable across platforms than persisting a raw Material codepoint.
class HabitIcons {
  HabitIcons._();

  static const Map<String, IconData> byKey = {
    'local_drink': Icons.local_drink_outlined,
    'book': Icons.menu_book_outlined,
    'fitness': Icons.fitness_center_outlined,
    'meditate': Icons.self_improvement_outlined,
    'school': Icons.school_outlined,
    'sleep': Icons.bedtime_outlined,
    'walk': Icons.directions_walk_outlined,
    'food': Icons.restaurant_outlined,
    'code': Icons.code_outlined,
    'brush': Icons.brush_outlined,
    'music': Icons.music_note_outlined,
    'savings': Icons.savings_outlined,
    'spa': Icons.spa_outlined,
    'language': Icons.language_outlined,
    'heart': Icons.favorite_outline,
    'sun': Icons.wb_sunny_outlined,
  };

  static List<String> get keys => byKey.keys.toList();

  static IconData iconFor(String key) => byKey[key] ?? Icons.check_circle_outline;
}

class Habit {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String iconKey;
  final int colorIndex;
  final HabitFrequency frequency;
  final String targetUnit; // e.g. "20 minutes", "8 glasses"
  final int targetValue;
  final bool reminderEnabled;
  final String? reminderTime; // 'HH:mm:ss'
  final DateTime startDate;
  final bool isActive;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.iconKey = 'heart',
    this.colorIndex = 0,
    this.frequency = const HabitFrequency(),
    this.targetUnit = '1 time',
    this.targetValue = 1,
    this.reminderEnabled = false,
    this.reminderTime,
    required this.startDate,
    this.isActive = true,
    required this.createdAt,
  });

  IconData get icon => HabitIcons.iconFor(iconKey);

  int? get reminderHour =>
      reminderTime != null ? int.tryParse(reminderTime!.split(':').first) : null;
  int? get reminderMinute =>
      reminderTime != null ? int.tryParse(reminderTime!.split(':')[1]) : null;

  Habit copyWith({
    String? title,
    String? description,
    String? category,
    String? iconKey,
    int? colorIndex,
    HabitFrequency? frequency,
    String? targetUnit,
    int? targetValue,
    bool? reminderEnabled,
    String? reminderTime,
    DateTime? startDate,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      iconKey: iconKey ?? this.iconKey,
      colorIndex: colorIndex ?? this.colorIndex,
      frequency: frequency ?? this.frequency,
      targetUnit: targetUnit ?? this.targetUnit,
      targetValue: targetValue ?? this.targetValue,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory Habit.fromRow(Map<String, dynamic> row) {
    return Habit(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      category: (row['category'] as String?) ?? 'General',
      iconKey: (row['icon'] as String?) ?? 'heart',
      colorIndex: (row['color_index'] as int?) ?? 0,
      frequency: HabitFrequency(
        type: frequencyTypeFromString(row['frequency_type'] as String?),
        customDays: (row['frequency_days'] as List?)?.map((e) => e as int).toList() ?? [],
      ),
      targetUnit: (row['target_unit'] as String?) ?? '1 time',
      targetValue: (row['target_value'] as int?) ?? 1,
      reminderEnabled: (row['reminder_enabled'] as bool?) ?? false,
      reminderTime: row['reminder_time'] as String?,
      startDate: DateTime.parse(row['start_date'] as String),
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
        'category': category,
        'icon': iconKey,
        'color_index': colorIndex,
        'frequency_type': frequency.type.name,
        'frequency_days': frequency.customDays,
        'target_unit': targetUnit,
        'target_value': targetValue,
        'reminder_enabled': reminderEnabled,
        'reminder_time': reminderTime,
        'start_date': startDate.toIso8601String().split('T').first,
        'is_active': isActive,
      };
}
