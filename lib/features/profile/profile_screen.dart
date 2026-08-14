import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_widgets.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final focusProvider = context.watch<FocusProvider>();
    final user = auth.currentUser!;

    final bestCurrentStreak = habitProvider.habits.isEmpty
        ? 0
        : habitProvider.habits
            .map((h) => habitProvider.statsFor(h.id).currentStreak)
            .reduce((a, b) => a > b ? a : b);

    final totalCompletions =
        habitProvider.habits.fold<int>(0, (sum, h) => sum + habitProvider.statsFor(h.id).totalCompletions);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primary.withOpacity(0.14),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: AppColors.lightTextSecondary)),
                if (user.isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Admin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Habits Completed', value: '$totalCompletions', icon: Icons.check_circle_outline, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Current Streak', value: '$bestCurrentStreak days', icon: Icons.local_fire_department_rounded, color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Tasks Done', value: '${taskProvider.completedTasks.length}', icon: Icons.task_alt_rounded, color: AppColors.info)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Focus Sessions', value: '${focusProvider.completedSessionsCount}', icon: Icons.timer_rounded, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 28),
          _ProfileTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _ProfileTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          if (user.isAdmin)
            _ProfileTile(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin Dashboard',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            ),
          const SizedBox(height: 12),
          _ProfileTile(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            color: AppColors.error,
            onTap: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Log out?',
                message: 'You can log back in anytime.',
                confirmLabel: 'Log Out',
              );
              if (!confirm) return;
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }
}
