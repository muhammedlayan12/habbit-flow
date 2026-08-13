import 'package:flutter/material.dart';

import '../../core/config/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _HabitAgg {
  final String title;
  final String category;
  int count = 0;
  int completions = 0;
  _HabitAgg(this.title, this.category);
}

class _RoutineAgg {
  final String title;
  int completions = 0;
  _RoutineAgg(this.title);
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  bool _loading = true;
  String? _error;
  List<_HabitAgg> _topHabits = [];
  Map<String, int> _categoryBreakdown = {};
  List<_RoutineAgg> _topRoutines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = SupabaseService.client;
    try {
      final habits = ((await client.from('habits').select('id, title, category')) as List)
          .cast<Map<String, dynamic>>();
      final completions =
          ((await client.from('habit_completions').select('habit_id')) as List).cast<Map<String, dynamic>>();
      final routines =
          ((await client.from('routines').select('id, title')) as List).cast<Map<String, dynamic>>();
      final routineCompletions = ((await client.from('routine_completions').select('routine_id')) as List)
          .cast<Map<String, dynamic>>();

      final byTitle = <String, _HabitAgg>{};
      final categoryCount = <String, int>{};
      for (final h in habits) {
        final title = (h['title'] as String?) ?? 'Untitled';
        final category = (h['category'] as String?) ?? 'General';
        byTitle.putIfAbsent(title, () => _HabitAgg(title, category));
        byTitle[title]!.count++;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      final completionsByHabitId = <String, int>{};
      for (final c in completions) {
        final id = c['habit_id'] as String;
        completionsByHabitId[id] = (completionsByHabitId[id] ?? 0) + 1;
      }
      // Roll completions up to title-level aggregates for a simple "most
      // popular habit" view across all users.
      final habitIdToTitle = {for (final h in habits) h['id'] as String: (h['title'] as String?) ?? 'Untitled'};
      for (final entry in completionsByHabitId.entries) {
        final title = habitIdToTitle[entry.key];
        if (title != null && byTitle.containsKey(title)) {
          byTitle[title]!.completions += entry.value;
        }
      }

      final routineAgg = <String, _RoutineAgg>{};
      for (final r in routines) {
        final title = (r['title'] as String?) ?? 'Untitled';
        routineAgg.putIfAbsent(title, () => _RoutineAgg(title));
      }
      final routineIdToTitle = {for (final r in routines) r['id'] as String: (r['title'] as String?) ?? 'Untitled'};
      for (final rc in routineCompletions) {
        final title = routineIdToTitle[rc['routine_id'] as String];
        if (title != null && routineAgg.containsKey(title)) {
          routineAgg[title]!.completions++;
        }
      }

      _topHabits = byTitle.values.toList()..sort((a, b) => b.count.compareTo(a.count));
      _categoryBreakdown = categoryCount;
      _topRoutines = routineAgg.values.toList()..sort((a, b) => b.completions.compareTo(a.completions));
    } catch (e) {
      _error = 'Could not load analytics.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits & Routines Analytics')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(icon: Icons.error_outline, title: 'Could not load data', message: _error!, actionLabel: 'Retry', onAction: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      const Text('Most Popular Habits', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_topHabits.isEmpty)
                        const EmptyState(icon: Icons.track_changes_outlined, title: 'No habits yet', message: 'Habit data will appear here once users start creating habits.')
                      else
                        AppCard(
                          child: Column(
                            children: _topHabits.take(8).map((h) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(h.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(h.category, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text('${h.count} users', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text('${h.completions} completions', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text('Habit Categories', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_categoryBreakdown.isEmpty)
                        const SizedBox.shrink()
                      else
                        AppCard(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categoryBreakdown.entries.map((e) {
                              return Chip(label: Text('${e.key} · ${e.value}'));
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text('Most Used Routines', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_topRoutines.isEmpty)
                        const EmptyState(icon: Icons.view_agenda_outlined, title: 'No routines yet', message: 'Routine data will appear here once users start creating routines.')
                      else
                        AppCard(
                          child: Column(
                            children: _topRoutines.take(8).map((r) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    Text('${r.completions} completions', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
