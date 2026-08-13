import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/focus_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/common_widgets.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const List<int> _presets = [15, 25, 45, 60];

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Mode')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: focus.timerStatus == FocusTimerStatus.finished
              ? _buildCompletion(context, focus)
              : _buildTimer(context, focus),
        ),
      ),
    );
  }

  Widget _buildTimer(BuildContext context, FocusProvider focus) {
    final progress = focus.totalSeconds == 0
        ? 0.0
        : 1 - (focus.remainingSeconds / focus.totalSeconds);
    final isIdle = focus.timerStatus == FocusTimerStatus.idle;

    return Column(
      children: [
        if (isIdle) ...[
          const Text('Choose a duration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ..._presets.map((m) => ChoiceChip(
                    label: Text('$m min'),
                    selected: focus.totalSeconds == m * 60,
                    onSelected: (_) => focus.configure(m),
                  )),
              ActionChip(
                label: const Text('Custom'),
                onPressed: () => _showCustomPicker(context, focus),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const Spacer(),
        ProgressRing(
          progress: progress,
          size: 260,
          strokeWidth: 16,
          color: AppColors.primary,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatTime(focus.remainingSeconds), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                focus.timerStatus == FocusTimerStatus.running
                    ? 'Focusing…'
                    : focus.timerStatus == FocusTimerStatus.paused
                        ? 'Paused'
                        : '${focus.totalSeconds ~/ 60} minute session',
                style: const TextStyle(color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            if (!isIdle)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => focus.reset(),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reset'),
                ),
              ),
            if (!isIdle) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: switch (focus.timerStatus) {
                  FocusTimerStatus.idle => 'Start',
                  FocusTimerStatus.running => 'Pause',
                  FocusTimerStatus.paused => 'Resume',
                  FocusTimerStatus.finished => 'Start',
                },
                icon: focus.timerStatus == FocusTimerStatus.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onPressed: () {
                  switch (focus.timerStatus) {
                    case FocusTimerStatus.idle:
                      focus.start();
                      break;
                    case FocusTimerStatus.running:
                      focus.pause();
                      break;
                    case FocusTimerStatus.paused:
                      focus.resume();
                      break;
                    case FocusTimerStatus.finished:
                      break;
                  }
                },
              ),
            ),
          ],
        ),
        if (focus.timerStatus == FocusTimerStatus.running || focus.timerStatus == FocusTimerStatus.paused) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: () => focus.finishEarly(), child: const Text('Finish now')),
        ],
        const SizedBox(height: 8),
        Text('${focus.completedSessionsCount} sessions completed all-time', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
      ],
    );
  }

  Widget _buildCompletion(BuildContext context, FocusProvider focus) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.14), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
        ),
        const SizedBox(height: 24),
        const Text('Focus Session Complete', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('You focused for ${focus.totalSeconds ~/ 60} minutes. Great work.', style: const TextStyle(color: AppColors.lightTextSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        AppButton(
          label: 'Start Another Session',
          onPressed: () {
            focus.configure(focus.totalSeconds ~/ 60);
          },
        ),
      ],
    );
  }

  void _showCustomPicker(BuildContext context, FocusProvider focus) {
    int minutes = 30;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Custom duration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setModalState(() => minutes = (minutes - 5).clamp(5, 180)),
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text('$minutes min', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => setModalState(() => minutes = (minutes + 5).clamp(5, 180)),
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Set Duration',
                onPressed: () {
                  focus.configure(minutes);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
