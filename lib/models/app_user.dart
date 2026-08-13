enum UserRole { user, admin }

UserRole roleFromString(String? value) => value == 'admin' ? UserRole.admin : UserRole.user;

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final bool onboardingComplete;
  final String? productivityGoal;
  final String? wakeUpTime;
  final String? sleepTime;
  final String? workStartTime;
  final String? workEndTime;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.role = UserRole.user,
    this.isActive = true,
    this.onboardingComplete = false,
    this.productivityGoal,
    this.wakeUpTime,
    this.sleepTime,
    this.workStartTime,
    this.workEndTime,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? fullName,
    String? avatarUrl,
    bool? isActive,
    bool? onboardingComplete,
    String? productivityGoal,
    String? wakeUpTime,
    String? sleepTime,
    String? workStartTime,
    String? workEndTime,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      isActive: isActive ?? this.isActive,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      productivityGoal: productivityGoal ?? this.productivityGoal,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      email: (row['email'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      role: roleFromString(row['role'] as String?),
      isActive: (row['is_active'] as bool?) ?? true,
      onboardingComplete: (row['onboarding_complete'] as bool?) ?? false,
      productivityGoal: row['productivity_goal'] as String?,
      wakeUpTime: row['wake_up_time'] as String?,
      sleepTime: row['sleep_time'] as String?,
      workStartTime: row['work_start_time'] as String?,
      workEndTime: row['work_end_time'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class UserPreferences {
  final String themeMode; // 'light' | 'dark' | 'system'
  final bool notificationsEnabled;
  final bool habitRemindersEnabled;
  final bool taskRemindersEnabled;
  final bool routineRemindersEnabled;
  final String timeFormat; // '12h' | '24h'
  final int weekStartsOn;
  final String dayStartTime; // 'HH:mm:ss'
  final String dayEndTime;

  const UserPreferences({
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.habitRemindersEnabled = true,
    this.taskRemindersEnabled = true,
    this.routineRemindersEnabled = true,
    this.timeFormat = '12h',
    this.weekStartsOn = 1,
    this.dayStartTime = '07:00:00',
    this.dayEndTime = '21:00:00',
  });

  UserPreferences copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    bool? habitRemindersEnabled,
    bool? taskRemindersEnabled,
    bool? routineRemindersEnabled,
    String? timeFormat,
    int? weekStartsOn,
    String? dayStartTime,
    String? dayEndTime,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      habitRemindersEnabled: habitRemindersEnabled ?? this.habitRemindersEnabled,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      routineRemindersEnabled: routineRemindersEnabled ?? this.routineRemindersEnabled,
      timeFormat: timeFormat ?? this.timeFormat,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      dayStartTime: dayStartTime ?? this.dayStartTime,
      dayEndTime: dayEndTime ?? this.dayEndTime,
    );
  }

  int get startHour => int.tryParse(dayStartTime.split(':').first) ?? 7;
  int get startMinute => int.tryParse(dayStartTime.split(':')[1]) ?? 0;
  int get endHour => int.tryParse(dayEndTime.split(':').first) ?? 21;
  int get endMinute => int.tryParse(dayEndTime.split(':')[1]) ?? 0;

  factory UserPreferences.fromRow(Map<String, dynamic> row) {
    return UserPreferences(
      themeMode: (row['theme_mode'] as String?) ?? 'system',
      notificationsEnabled: (row['notifications_enabled'] as bool?) ?? true,
      habitRemindersEnabled: (row['habit_reminders_enabled'] as bool?) ?? true,
      taskRemindersEnabled: (row['task_reminders_enabled'] as bool?) ?? true,
      routineRemindersEnabled: (row['routine_reminders_enabled'] as bool?) ?? true,
      timeFormat: (row['time_format'] as String?) ?? '12h',
      weekStartsOn: (row['week_starts_on'] as int?) ?? 1,
      dayStartTime: (row['day_start_time'] as String?) ?? '07:00:00',
      dayEndTime: (row['day_end_time'] as String?) ?? '21:00:00',
    );
  }

  Map<String, dynamic> toRow() => {
        'theme_mode': themeMode,
        'notifications_enabled': notificationsEnabled,
        'habit_reminders_enabled': habitRemindersEnabled,
        'task_reminders_enabled': taskRemindersEnabled,
        'routine_reminders_enabled': routineRemindersEnabled,
        'time_format': timeFormat,
        'week_starts_on': weekStartsOn,
        'day_start_time': dayStartTime,
        'day_end_time': dayEndTime,
      };
}
