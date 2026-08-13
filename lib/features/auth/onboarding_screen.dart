import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/seed_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../main/main_nav_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  final _goalController = TextEditingController();
  final _workHoursController = TextEditingController();
  String? _wakeTime;
  String? _sleepTime;
  final Set<String> _selectedHabits = {};

  static const _habitOptions = [
    'Drink Water', 'Read', 'Exercise', 'Meditate', 'Study', 'Sleep on Time', 'Journal',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _goalController.dispose();
    _workHoursController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _skip() => _next();

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final auth = context.read<AuthProvider>();
    await auth.completeOnboarding(
      mainGoal: _goalController.text.trim().isEmpty ? null : _goalController.text.trim(),
      wakeUpTime: _wakeTime,
      sleepTime: _sleepTime,
      workHours: _workHoursController.text.trim().isEmpty ? null : _workHoursController.text.trim(),
    );

    final userId = auth.currentUser!.id;
    final habitProvider = context.read<HabitProvider>();
    final taskProvider = context.read<TaskProvider>();
    final routineProvider = context.read<RoutineProvider>();
    await habitProvider.loadForUser(userId);
    await taskProvider.loadForUser(userId);
    await routineProvider.loadForUser(userId);

    if (habitProvider.habits.isEmpty) {
      await SeedService.seedForNewUser(
        habitProvider: habitProvider,
        taskProvider: taskProvider,
        routineProvider: routineProvider,
      );
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 48),
            SizedBox(height: 16),
            Text(
              'Your productivity system is ready.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Enter HabitFlow'),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  }

  Future<void> _pickTime(bool isWake) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      final formatted = picked.format(context);
      if (isWake) {
        _wakeTime = formatted;
      } else {
        _sleepTime = formatted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().currentUser?.fullName.split(' ').first ?? '';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(4, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _page ? AppColors.primary : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  TextButton(onPressed: _finishing ? null : _skip, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _step(
                    title: 'Welcome, $name 👋',
                    subtitle: "What's your main productivity goal?",
                    child: AppTextField(
                      controller: _goalController,
                      label: 'e.g. Build a consistent morning routine',
                      maxLines: 2,
                    ),
                  ),
                  _step(
                    title: 'Your daily rhythm',
                    subtitle: 'When do you usually wake up and sleep?',
                    child: Column(
                      children: [
                        _timePickerTile('Wake-up time', _wakeTime, () => _pickTime(true)),
                        const SizedBox(height: 12),
                        _timePickerTile('Sleep time', _sleepTime, () => _pickTime(false)),
                      ],
                    ),
                  ),
                  _step(
                    title: 'Work & study hours',
                    subtitle: 'When are you usually focused on work or study?',
                    child: AppTextField(
                      controller: _workHoursController,
                      label: 'e.g. 9:00 AM – 5:00 PM',
                    ),
                  ),
                  _step(
                    title: 'Habits you want to build',
                    subtitle: 'Pick a few to start with — you can add more later.',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _habitOptions.map((h) {
                        final selected = _selectedHabits.contains(h);
                        return FilterChip(
                          label: Text(h),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            v ? _selectedHabits.add(h) : _selectedHabits.remove(h);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: _page == 3 ? "Let's Go" : 'Continue',
                isLoading: _finishing,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerTile(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label),
            const Spacer(),
            Text(value ?? 'Select', style: const TextStyle(color: AppColors.lightTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _step({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}
