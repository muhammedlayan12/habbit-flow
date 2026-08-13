import '../models/habit.dart';
import '../models/routine.dart';
import '../models/task_item.dart';
import '../providers/habit_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/task_provider.dart';

/// Generates realistic sample data for a brand-new account so the app never
/// feels empty on first launch. Everything it creates is written straight
/// to Supabase through the normal provider methods — there is no separate
/// "demo mode" data path to keep in sync.
///
/// To ship without demo data, stop calling [seedForNewUser] from the
/// onboarding completion step — no other code needs to change.
class SeedService {
  SeedService._();

  static Future<void> seedForNewUser({
    required HabitProvider habitProvider,
    required TaskProvider taskProvider,
    required RoutineProvider routineProvider,
  }) async {
    await habitProvider.createHabit(
      title: 'Drink Water',
      description: 'Stay hydrated throughout the day.',
      category: 'Health',
      iconKey: 'local_drink',
      colorIndex: 0,
      frequency: const HabitFrequency(type: HabitFrequencyType.daily),
      targetUnit: '8 glasses',
      targetValue: 8,
    );
    await habitProvider.createHabit(
      title: 'Read 20 Minutes',
      description: 'Read a book, article, or anything that teaches you something.',
      category: 'Growth',
      iconKey: 'book',
      colorIndex: 1,
      frequency: const HabitFrequency(type: HabitFrequencyType.daily),
      targetUnit: '20 minutes',
      targetValue: 20,
    );
    await habitProvider.createHabit(
      title: 'Exercise',
      description: 'Move your body — gym, walk, or home workout.',
      category: 'Fitness',
      iconKey: 'fitness',
      colorIndex: 2,
      frequency: const HabitFrequency(type: HabitFrequencyType.weekdays),
      targetUnit: '30 minutes',
      targetValue: 30,
    );
    await habitProvider.createHabit(
      title: 'Meditate',
      description: 'A few minutes of stillness to reset your mind.',
      category: 'Mindfulness',
      iconKey: 'meditate',
      colorIndex: 3,
      frequency: const HabitFrequency(type: HabitFrequencyType.daily),
      targetUnit: '10 minutes',
      targetValue: 10,
    );
    await habitProvider.createHabit(
      title: 'Sleep on Time',
      description: 'Wind down and get to bed at a consistent time.',
      category: 'Health',
      iconKey: 'sleep',
      colorIndex: 4,
      frequency: const HabitFrequency(type: HabitFrequencyType.daily),
      targetUnit: '1 time',
      targetValue: 1,
    );

    final today = DateTime.now();
    await taskProvider.createTask(
      title: 'Plan tomorrow',
      description: 'Write down your top 3 priorities for tomorrow.',
      priority: TaskPriority.medium,
      dueDate: today,
      dueHour: 20,
      dueMinute: 0,
    );
    await taskProvider.createTask(
      title: 'Reply to emails',
      description: 'Clear your inbox before end of day.',
      priority: TaskPriority.low,
      dueDate: today,
      dueHour: 17,
      dueMinute: 0,
    );
    await taskProvider.createTask(
      title: 'Review notes',
      description: 'Go over what you learned today.',
      priority: TaskPriority.medium,
      dueDate: today.add(const Duration(days: 1)),
    );
    await taskProvider.createTask(
      title: 'Complete project milestone',
      description: 'Push forward the current work project.',
      priority: TaskPriority.high,
      dueDate: today.add(const Duration(days: 2)),
      dueHour: 18,
      dueMinute: 0,
    );

    await routineProvider.createRoutine(
      title: 'Morning Routine',
      description: 'Start the day with intention.',
      startHour: 7,
      startMinute: 0,
      colorIndex: 0,
      steps: [
        RoutineStep(id: '', routineId: '', title: 'Wake Up', order: 0, durationSeconds: 60),
        RoutineStep(id: '', routineId: '', title: 'Drink Water', order: 1, durationSeconds: 120),
        RoutineStep(id: '', routineId: '', title: 'Stretch', order: 2, durationSeconds: 300),
        RoutineStep(id: '', routineId: '', title: 'Shower', order: 3, durationSeconds: 600),
        RoutineStep(id: '', routineId: '', title: 'Breakfast', order: 4, durationSeconds: 900),
      ],
    );
    await routineProvider.createRoutine(
      title: 'Evening Routine',
      description: 'Wind down and prepare for tomorrow.',
      startHour: 21,
      startMinute: 0,
      colorIndex: 2,
      steps: [
        RoutineStep(id: '', routineId: '', title: 'Tidy Up', order: 0, durationSeconds: 300),
        RoutineStep(id: '', routineId: '', title: 'Plan Tomorrow', order: 1, durationSeconds: 300),
        RoutineStep(id: '', routineId: '', title: 'Read', order: 2, durationSeconds: 600),
        RoutineStep(id: '', routineId: '', title: 'Lights Out', order: 3, durationSeconds: 60),
      ],
    );
  }
}
