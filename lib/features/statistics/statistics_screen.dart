import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/focus_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final routineProvider = context.watch<RoutineProvider>();
    final focusProvider = context.watch<FocusProvider>();

    final weeklyRatio = habitProvider.weeklyCompletionRatio();
    final days = weeklyRatio.keys.toList();
    final today = DateTime.now();

    final scheduledToday = habitProvider.habitsScheduledFor(today);
    final completedToday = scheduledToday.where((h) => habitProvider.isCompletedOn(h.id, today)).length;
    final dailyRate = scheduledToday.isEmpty ? 0.0 : completedToday / scheduledToday.length;

    final weeklyAvg = weeklyRatio.values.isEmpty
        ? 0.0
        : weeklyRatio.values.reduce((a, b) => a + b) / weeklyRatio.values.length;

    // Best current streak across all habits, for the achievement card.
    final bestCurrentStreak = habitProvider.habits.isEmpty
        ? 0
        : habitProvider.habits.map((h) => habitProvider.statsFor(h.id).currentStreak).reduce((a, b) => a > b ? a : b);

    final productivityScore = ((dailyRate * 0.4 + weeklyAvg * 0.4 + (taskProvider.completedThisWeekCount > 0 ? 0.2 : 0)) * 100).clamp(0, 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ProgressRing(
                  progress: productivityScore / 100,
                  size: 88,
                  strokeWidth: 9,
                  color: AppColors.primary,
                  center: Text('$productivityScore', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Productivity Score', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'Based on today, this week, and task completion.',
                        style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(label: 'Daily Completion', value: '${(dailyRate * 100).round()}%', icon: Icons.today_rounded, color: AppColors.primary),
              StatCard(label: 'Weekly Completion', value: '${(weeklyAvg * 100).round()}%', icon: Icons.calendar_view_week_rounded, color: AppColors.accent),
              StatCard(label: 'Best Active Streak', value: '$bestCurrentStreak days', icon: Icons.local_fire_department_rounded, color: AppColors.warning),
              StatCard(label: 'Tasks This Week', value: '${taskProvider.completedThisWeekCount}', icon: Icons.task_alt_rounded, color: AppColors.info),
              StatCard(label: 'Focus Sessions', value: '${focusProvider.completedSessionsCount}', icon: Icons.timer_rounded, color: AppColors.success),
              StatCard(label: 'Routines This Week', value: '${routineProvider.totalCompletionsThisWeek}', icon: Icons.view_agenda_rounded, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Weekly Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: 1,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(AppDateUtils.weekdayShort(days[index]), style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(days.length, (i) {
                    final ratio = weeklyRatio[days[i]] ?? 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: ratio.clamp(0.03, 1),
                          color: AppColors.primary,
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _AchievementsRow(
            bestStreak: bestCurrentStreak,
            totalHabits: habitProvider.habits.length,
            focusSessions: focusProvider.completedSessionsCount,
            tasksCompleted: taskProvider.completedTasks.length,
          ),
        ],
      ),
    );
  }
}

class _AchievementsRow extends StatelessWidget {
  final int bestStreak;
  final int totalHabits;
  final int focusSessions;
  final int tasksCompleted;

  const _AchievementsRow({
    required this.bestStreak,
    required this.totalHabits,
    required this.focusSessions,
    required this.tasksCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement('7-Day Streak', Icons.local_fire_department_rounded, bestStreak >= 7, AppColors.warning),
      _Achievement('30-Day Streak', Icons.whatshot_rounded, bestStreak >= 30, AppColors.error),
      _Achievement('5 Habits Built', Icons.track_changes_rounded, totalHabits >= 5, AppColors.primary),
      _Achievement('10 Focus Sessions', Icons.timer_rounded, focusSessions >= 10, AppColors.success),
      _Achievement('25 Tasks Done', Icons.task_alt_rounded, tasksCompleted >= 25, AppColors.info),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = achievements[i];
          return Container(
            width: 96,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: a.unlocked ? a.color.withOpacity(0.1) : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: a.unlocked ? a.color.withOpacity(0.3) : AppColors.lightBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.icon, color: a.unlocked ? a.color : AppColors.lightTextSecondary, size: 26),
                const SizedBox(height: 8),
                Text(
                  a.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: a.unlocked ? null : AppColors.lightTextSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Achievement {
  final String title;
  final IconData icon;
  final bool unlocked;
  final Color color;
  _Achievement(this.title, this.icon, this.unlocked, this.color);
}
