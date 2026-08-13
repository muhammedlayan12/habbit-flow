import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_widgets.dart';
import 'create_habit_screen.dart';

class HabitDetailsScreen extends StatefulWidget {
  final String habitId;
  const HabitDetailsScreen({super.key, required this.habitId});

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final habit = habitProvider.habits.where((h) => h.id == widget.habitId);
    if (habit.isEmpty) {
      return const Scaffold(body: Center(child: Text('Habit not found')));
    }
    final h = habit.first;
    final stats = habitProvider.statsFor(h.id);
    final color = AppColors.colorForIndex(h.colorIndex);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(h.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateHabitScreen(existing: h))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Delete habit?',
                message: 'This will permanently remove "${h.title}" and its history.',
                confirmLabel: 'Delete',
              );
              if (confirm) {
                await habitProvider.deleteHabit(h.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (h.description.isNotEmpty) ...[
            Text(h.description, style: const TextStyle(color: AppColors.lightTextSecondary)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(child: StatCard(label: 'Current Streak', value: '${stats.currentStreak} days', icon: Icons.local_fire_department_rounded, color: AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Best Streak', value: '${stats.bestStreak} days', icon: Icons.emoji_events_rounded, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Completion Rate', value: '${(stats.completionRate * 100).round()}%', icon: Icons.donut_large_rounded, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Total Completions', value: '${stats.totalCompletions}', icon: Icons.check_circle_outline, color: AppColors.info)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              FilledButton.icon(
                onPressed: () => habitProvider.toggleCompletion(h.id),
                icon: Icon(habitProvider.isCompletedOn(h.id, today) ? Icons.check : Icons.circle_outlined, size: 18),
                label: Text(habitProvider.isCompletedOn(h.id, today) ? 'Completed' : 'Mark Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor: habitProvider.isCompletedOn(h.id, today) ? AppColors.success : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Weekly Performance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(child: _WeeklyChart(habitId: h.id, color: color)),
          const SizedBox(height: 24),
          const Text('Calendar History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TableCalendar(
              firstDay: h.startDate.subtract(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 1)),
              focusedDay: _focusedDay,
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarFormat: CalendarFormat.month,
              onPageChanged: (day) => setState(() => _focusedDay = day),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => _dayCell(day, habitProvider, h.id, color),
                todayBuilder: (context, day, focusedDay) => _dayCell(day, habitProvider, h.id, color, isToday: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime day, HabitProvider provider, String habitId, Color color, {bool isToday = false}) {
    final completed = provider.isCompletedOn(habitId, day);
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? color.withOpacity(0.85) : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday && !completed ? Border.all(color: color) : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(color: completed ? Colors.white : null, fontWeight: completed ? FontWeight.w700 : null),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final String habitId;
  final Color color;
  const _WeeklyChart({required this.habitId, required this.color});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final days = AppDateUtils.lastNDays(7);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: 1.2,
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
            final done = habitProvider.isCompletedOn(habitId, days[i]);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: done ? 1 : 0.06,
                  color: done ? color : color.withOpacity(0.15),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
