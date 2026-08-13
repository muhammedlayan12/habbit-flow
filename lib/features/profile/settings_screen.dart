import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prefs = auth.preferences;

    Future<void> updatePrefs(UserPreferences Function(UserPreferences) update) async {
      await auth.updatePreferences(update(prefs));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionLabel('Preferences'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications'),
                  subtitle: const Text('Master switch for all reminders'),
                  value: prefs.notificationsEnabled,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(notificationsEnabled: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Habit reminders'),
                  value: prefs.habitRemindersEnabled,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(habitRemindersEnabled: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Task reminders'),
                  value: prefs.taskRemindersEnabled,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(taskRemindersEnabled: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Routine reminders'),
                  value: prefs.routineRemindersEnabled,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(routineRemindersEnabled: v)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start-of-day reminder'),
                  subtitle: Text('${prefs.startHour.toString().padLeft(2, '0')}:${prefs.startMinute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: prefs.startHour, minute: prefs.startMinute),
                    );
                    if (picked != null) {
                      updatePrefs((p) => p.copyWith(
                          dayStartTime: '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00'));
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End-of-day reminder'),
                  subtitle: Text('${prefs.endHour.toString().padLeft(2, '0')}:${prefs.endMinute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: prefs.endHour, minute: prefs.endMinute),
                    );
                    if (picked != null) {
                      updatePrefs((p) => p.copyWith(
                          dayEndTime: '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00'));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Week starts on'),
                  trailing: DropdownButton<int>(
                    value: prefs.weekStartsOn,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Monday')),
                      DropdownMenuItem(value: 7, child: Text('Sunday')),
                    ],
                    onChanged: (v) {
                      if (v != null) updatePrefs((p) => p.copyWith(weekStartsOn: v));
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Time format'),
                  trailing: DropdownButton<String>(
                    value: prefs.timeFormat,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: '12h', child: Text('12-hour')),
                      DropdownMenuItem(value: '24h', child: Text('24-hour')),
                    ],
                    onChanged: (v) {
                      if (v != null) updatePrefs((p) => p.copyWith(timeFormat: v));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Appearance'),
          AppCard(
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Light'),
                  value: 'light',
                  groupValue: prefs.themeMode,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(themeMode: v)),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark'),
                  value: 'dark',
                  groupValue: prefs.themeMode,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(themeMode: v)),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('System default'),
                  value: 'system',
                  groupValue: prefs.themeMode,
                  onChanged: (v) => updatePrefs((p) => p.copyWith(themeMode: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Account'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Log out', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    final confirm = await showConfirmDialog(context, title: 'Log out?', message: 'You can log back in anytime.', confirmLabel: 'Log Out');
                    if (!confirm) return;
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('About'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HabitFlow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Build better days, one habit at a time.', style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                const Text('Designed & Developed by Muhammad Layan', style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => launchUrl(Uri.parse('https://muhammadlayan.vercel.app/'), mode: LaunchMode.externalApplication),
                  child: const Text(
                    'muhammadlayan.vercel.app',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.lightTextSecondary)),
    );
  }
}
