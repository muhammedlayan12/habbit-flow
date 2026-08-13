import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/common_widgets.dart';
import 'create_routine_screen.dart';
import 'routine_timer_screen.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<RoutineProvider>();
    final routines = routineProvider.routines;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRoutineScreen())),
          ),
        ],
      ),
      body: routineProvider.isLoading
          ? const LoadingView()
          : routines.isEmpty
              ? EmptyState(
                  icon: Icons.view_agenda_outlined,
                  title: 'No routines yet',
                  message: 'Build a morning, work, or evening routine with ordered steps.',
                  actionLabel: 'Create Routine',
                  onAction: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const CreateRoutineScreen())),
                )
              : RefreshIndicator(
                  onRefresh: () => routineProvider.loadForUser(routines.first.userId),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: routines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => _RoutineCard(routine: routines[i]),
                  ),
                ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<RoutineProvider>();
    final steps = routineProvider.stepsFor(routine.id);
    final color = AppColors.colorForIndex(routine.colorIndex);
    final completedToday = routineProvider.isCompletedOn(routine.id, DateTime.now());
    final totalSeconds = steps.fold<int>(0, (sum, s) => sum + s.durationSeconds);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.view_agenda_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(routine.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      '${_formatTime(routine.startHour, routine.startMinute)} · ${steps.length} steps · ${(totalSeconds / 60).round()} min',
                      style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              if (completedToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Done today', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => CreateRoutineScreen(existing: routine)));
                      break;
                    case 'delete':
                      final confirm = await showConfirmDialog(
                        context,
                        title: 'Delete routine?',
                        message: 'This will permanently remove "${routine.title}" and its steps.',
                        confirmLabel: 'Delete',
                      );
                      if (confirm) await routineProvider.deleteRoutine(routine.id);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...steps.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.title, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                      Text('${(s.durationSeconds / 60).ceil()} min', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                    ],
                  ),
                )),
            if (steps.length > 3)
              Text('+ ${steps.length - 3} more', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: steps.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineTimerScreen(routineId: routine.id))),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start Routine'),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
