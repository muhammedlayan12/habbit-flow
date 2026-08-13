import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_widgets.dart';
import 'admin_content_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminStats {
  int totalUsers = 0;
  int activeUsers = 0;
  int newUsersThisWeek = 0;
  int totalHabits = 0;
  int habitCompletions = 0;
  int totalTasks = 0;
  int completedTasks = 0;
  int totalRoutines = 0;
  int routineCompletions = 0;
  int focusSessions = 0;
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  final _stats = _AdminStats();

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
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

      final profiles = await client.from('profiles').select('id, is_active, created_at');
      final habits = await client.from('habits').select('id');
      final habitCompletions = await client.from('habit_completions').select('id');
      final tasks = await client.from('tasks').select('id, completed');
      final routines = await client.from('routines').select('id');
      final routineCompletions = await client.from('routine_completions').select('id');
      final focusSessions = await client.from('focus_sessions').select('id, completed');

      final profileList = (profiles as List).cast<Map<String, dynamic>>();
      final taskList = (tasks as List).cast<Map<String, dynamic>>();
      final focusList = (focusSessions as List).cast<Map<String, dynamic>>();

      _stats.totalUsers = profileList.length;
      _stats.activeUsers = profileList.where((p) => p['is_active'] == true).length;
      _stats.newUsersThisWeek =
          profileList.where((p) => (p['created_at'] as String?)?.compareTo(weekAgo) == 1).length;
      _stats.totalHabits = (habits as List).length;
      _stats.habitCompletions = (habitCompletions as List).length;
      _stats.totalTasks = taskList.length;
      _stats.completedTasks = taskList.where((t) => t['completed'] == true).length;
      _stats.totalRoutines = (routines as List).length;
      _stats.routineCompletions = (routineCompletions as List).length;
      _stats.focusSessions = focusList.where((f) => f['completed'] == true).length;
    } catch (e) {
      _error = 'Could not load admin statistics. Confirm this account has the admin role.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin access only.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(icon: Icons.error_outline, title: 'Could not load data', message: _error!, actionLabel: 'Retry', onAction: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      const Text('Users', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          StatCard(label: 'Total Users', value: '${_stats.totalUsers}', icon: Icons.people_alt_rounded, color: AppColors.primary),
                          StatCard(label: 'Active Users', value: '${_stats.activeUsers}', icon: Icons.person_rounded, color: AppColors.success),
                          StatCard(label: 'New This Week', value: '${_stats.newUsersThisWeek}', icon: Icons.person_add_alt_1_rounded, color: AppColors.accent),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Content', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          StatCard(label: 'Total Habits', value: '${_stats.totalHabits}', icon: Icons.track_changes_rounded, color: AppColors.primary),
                          StatCard(label: 'Habit Completions', value: '${_stats.habitCompletions}', icon: Icons.check_circle_outline, color: AppColors.success),
                          StatCard(label: 'Tasks Created', value: '${_stats.totalTasks}', icon: Icons.task_alt_rounded, color: AppColors.info),
                          StatCard(label: 'Tasks Completed', value: '${_stats.completedTasks}', icon: Icons.done_all_rounded, color: AppColors.info),
                          StatCard(label: 'Routines Created', value: '${_stats.totalRoutines}', icon: Icons.view_agenda_rounded, color: AppColors.accent),
                          StatCard(label: 'Routine Completions', value: '${_stats.routineCompletions}', icon: Icons.playlist_add_check_rounded, color: AppColors.accent),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StatCard(label: 'Completed Focus Sessions', value: '${_stats.focusSessions}', icon: Icons.timer_rounded, color: AppColors.warning),
                      const SizedBox(height: 28),
                      const Text('Management', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      AppCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
                        child: const Row(
                          children: [
                            Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(child: Text('User Management')),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminContentScreen())),
                        child: const Row(
                          children: [
                            Icon(Icons.insights_rounded, color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(child: Text('Habits & Routines Analytics')),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
