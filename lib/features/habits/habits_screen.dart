import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common_widgets.dart';
import 'create_habit_screen.dart';
import 'habit_details_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final today = DateTime.now();

    List<Habit> filterFor(int tabIndex) {
      switch (tabIndex) {
        case 0:
          return habitProvider.habits;
        case 1:
          return habitProvider.habitsScheduledFor(today);
        case 2:
          return habitProvider.habits.where((h) => h.isActive).toList();
        case 3:
          return habitProvider.habits
              .where((h) => habitProvider.isCompletedOn(h.id, today))
              .toList();
        default:
          return [];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateHabitScreen())),
          ),
        ],
      ),
      body: habitProvider.isLoading
          ? const LoadingView()
          : TabBarView(
              controller: _tabController,
              children: List.generate(4, (i) {
                final list = filterFor(i);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.track_changes_outlined,
                    title: 'No habits yet',
                    message: 'Create your first habit and start building a better routine.',
                    actionLabel: 'Create Habit',
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateHabitScreen())),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _HabitDetailCard(habit: list[index]),
                );
              }),
            ),
    );
  }
}

class _HabitDetailCard extends StatelessWidget {
  final Habit habit;
  const _HabitDetailCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final stats = habitProvider.statsFor(habit.id);
    final color = AppColors.colorForIndex(habit.colorIndex);
    final week = AppDateUtils.lastNDays(7);

    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HabitDetailsScreen(habitId: habit.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(habit.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(habit.frequency.label, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                  ],
                ),
              ),
              if (!habit.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Paused', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w700)),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateHabitScreen(existing: habit)));
                      break;
                    case 'pause':
                      await habitProvider.togglePause(habit.id);
                      break;
                    case 'delete':
                      final confirm = await showConfirmDialog(
                        context,
                        title: 'Delete habit?',
                        message: 'This will permanently remove "${habit.title}" and its history.',
                        confirmLabel: 'Delete',
                      );
                      if (confirm) await habitProvider.deleteHabit(habit.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'pause', child: Text(habit.isActive ? 'Pause' : 'Resume')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('${stats.currentStreak} day streak', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.emoji_events_outlined, size: 14, color: AppColors.lightTextSecondary),
              const SizedBox(width: 4),
              Text('Best ${stats.bestStreak}', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
              const Spacer(),
              Text('${(stats.completionRate * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: week.map((day) {
              final done = habitProvider.isCompletedOn(habit.id, day);
              final scheduled = habit.frequency.occursOn(day);
              return Column(
                children: [
                  Text(AppDateUtils.weekdayShort(day), style: const TextStyle(fontSize: 10, color: AppColors.lightTextSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.success : Colors.transparent,
                      border: Border.all(color: scheduled ? (done ? AppColors.success : color.withOpacity(0.4)) : AppColors.lightBorder),
                    ),
                    child: Icon(
                      done ? Icons.check : (scheduled ? Icons.circle_outlined : Icons.remove),
                      size: 12,
                      color: done ? Colors.white : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
