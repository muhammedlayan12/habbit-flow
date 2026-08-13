import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_widgets.dart';
import '../focus/focus_screen.dart';
import '../habits/create_habit_screen.dart';
import '../habits/habit_details_screen.dart';
import '../routines/create_routine_screen.dart';
import '../statistics/statistics_screen.dart';
import '../tasks/create_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final routineProvider = context.watch<RoutineProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = auth.currentUser!;
    final today = DateTime.now();

    final scheduledHabits = habitProvider.habitsScheduledFor(today);
    final completedHabits = scheduledHabits.where((h) => habitProvider.isCompletedOn(h.id, today)).length;
    final todayTasks = taskProvider.todayTasks;
    final totalToday = scheduledHabits.length + todayTasks.length + taskProvider.tasksDueOn(today).where((t) => t.completed).length;
    final completedToday = completedHabits + taskProvider.tasksDueOn(today).where((t) => t.completed).length;
    final progress = totalToday == 0 ? 0.0 : completedToday / totalToday;

    final scheduleItems = _buildSchedule(routineProvider, taskProvider, today);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await habitProvider.loadForUser(user.id);
            await taskProvider.loadForUser(user.id);
            await routineProvider.loadForUser(user.id);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppDateUtils.greeting()}, ${user.fullName.split(' ').first}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.friendlyDate(today),
                          style: const TextStyle(color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.14),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _motivationalMessage(progress),
                style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              _ProgressCard(
                progress: progress,
                completed: completedToday,
                total: totalToday,
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: "Today's Habits"),
              if (scheduledHabits.isEmpty)
                const EmptyState(
                  icon: Icons.track_changes_outlined,
                  title: 'No habits yet',
                  message: 'Create your first habit and start building a better routine.',
                )
              else
                ...scheduledHabits.map((habit) {
                  final stats = habitProvider.statsFor(habit.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HabitCard(
                      habit: habit,
                      stats: stats,
                      completedToday: habitProvider.isCompletedOn(habit.id, today),
                      onToggle: () => habitProvider.toggleCompletion(habit.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => HabitDetailsScreen(habitId: habit.id)),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 12),
              const SectionHeader(title: "Today's Schedule"),
              if (scheduleItems.isEmpty)
                const EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Nothing scheduled',
                  message: 'Add a routine or a task to see your timeline here.',
                )
              else
                AppCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < scheduleItems.length; i++) ...[
                        _ScheduleRow(item: scheduleItems[i]),
                        if (i != scheduleItems.length - 1) const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Quick Actions'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: [
                  _QuickAction(
                    label: 'Add Habit',
                    icon: Icons.add_task_rounded,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateHabitScreen())),
                  ),
                  _QuickAction(
                    label: 'Add Task',
                    icon: Icons.playlist_add_rounded,
                    color: AppColors.info,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
                  ),
                  _QuickAction(
                    label: 'Add Routine',
                    icon: Icons.view_agenda_outlined,
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRoutineScreen())),
                  ),
                  _QuickAction(
                    label: 'Start Focus',
                    icon: Icons.timer_outlined,
                    color: AppColors.warning,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                child: Row(
                  children: const [
                    Icon(Icons.insights_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(child: Text('View full statistics & progress history')),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _motivationalMessage(double progress) {
    if (progress >= 1.0) return "Perfect day. You're unstoppable. 🎉";
    if (progress >= 0.6) return "Strong momentum — keep the streak alive.";
    if (progress > 0) return "Good start. A few more to go today.";
    return "A fresh day, full of potential.";
  }

  List<_ScheduleItem> _buildSchedule(
    RoutineProvider routineProvider,
    TaskProvider taskProvider,
    DateTime today,
  ) {
    final items = <_ScheduleItem>[];
    for (final r in routineProvider.routines.where((r) => r.isActive)) {
      items.add(_ScheduleItem(
        hour: r.startHour,
        minute: r.startMinute,
        title: r.title,
        subtitle: '${routineProvider.stepsFor(r.id).length} steps',
        icon: Icons.view_agenda_outlined,
        color: AppColors.colorForIndex(r.colorIndex),
      ));
    }
    for (final t in taskProvider.tasksDueOn(today)) {
      items.add(_ScheduleItem(
        hour: t.dueHour ?? 23,
        minute: t.dueMinute ?? 59,
        title: t.title,
        subtitle: t.completed ? 'Completed' : 'Task',
        icon: Icons.task_alt_rounded,
        color: AppColors.info,
      ));
    }
    items.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return items;
  }
}

class _ScheduleItem {
  final int hour;
  final int minute;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _ScheduleItem({
    required this.hour,
    required this.minute,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ScheduleRow extends StatelessWidget {
  final _ScheduleItem item;
  const _ScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            AppDateUtils.formatTimeOfDay(item.hour, item.minute),
            style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: item.color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(item.icon, size: 17, color: item.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const _ProgressCard({required this.progress, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final remaining = (total - completed).clamp(0, total);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 96,
            strokeWidth: 10,
            color: AppColors.primary,
            center: Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Progress", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '$completed completed · $remaining remaining',
                  style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text('$total total today', style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
