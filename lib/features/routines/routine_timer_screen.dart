import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/common_widgets.dart';

class RoutineTimerScreen extends StatefulWidget {
  final String routineId;
  const RoutineTimerScreen({super.key, required this.routineId});

  @override
  State<RoutineTimerScreen> createState() => _RoutineTimerScreenState();
}

enum _TimerState { running, paused, finished }

class _RoutineTimerScreenState extends State<RoutineTimerScreen> {
  late List<RoutineStep> _steps;
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  _TimerState _state = _TimerState.running;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _steps = context.read<RoutineProvider>().stepsFor(widget.routineId);
    if (_steps.isNotEmpty) {
      _remainingSeconds = _steps.first.durationSeconds;
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state != _TimerState.running) return;
      setState(() {
        if (_remainingSeconds <= 1) {
          _goToNextStep();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _goToNextStep() {
    if (_currentIndex >= _steps.length - 1) {
      _finish();
      return;
    }
    _currentIndex++;
    _remainingSeconds = _steps[_currentIndex].durationSeconds;
  }

  void _skip() {
    setState(() {
      _goToNextStep();
    });
  }

  void _togglePause() {
    setState(() {
      _state = _state == _TimerState.running ? _TimerState.paused : _TimerState.running;
    });
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    setState(() => _state = _TimerState.finished);
    await context.read<RoutineProvider>().markCompleted(widget.routineId);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routine = context.watch<RoutineProvider>().routines.firstWhere((r) => r.id == widget.routineId);
    final color = AppColors.colorForIndex(routine.colorIndex);

    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(routine.title)),
        body: const EmptyState(icon: Icons.view_agenda_outlined, title: 'No steps', message: 'Add steps to this routine first.'),
      );
    }

    if (_state == _TimerState.finished) {
      return _buildCompletionScreen(context, routine, color);
    }

    final step = _steps[_currentIndex];
    final nextStep = _currentIndex < _steps.length - 1 ? _steps[_currentIndex + 1] : null;
    final progress = 1 - (_remainingSeconds / step.durationSeconds);

    return Scaffold(
      backgroundColor: color.withOpacity(0.04),
      appBar: AppBar(title: Text(routine.title), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _steps.length,
                backgroundColor: color.withOpacity(0.12),
                color: color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text('Step ${_currentIndex + 1} of ${_steps.length}', style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13)),
              const Spacer(),
              Text(step.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              if (step.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(step.notes, style: const TextStyle(color: AppColors.lightTextSecondary), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              ProgressRing(
                progress: progress,
                size: 220,
                strokeWidth: 14,
                color: color,
                center: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 32),
              if (nextStep != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: Text('Next: ${nextStep.title}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skip,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _state == _TimerState.running ? 'Pause' : 'Resume',
                      icon: _state == _TimerState.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: color,
                      onPressed: _togglePause,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _finish, child: const Text('Finish routine now')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, Routine routine, Color color) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: color, size: 56),
              ),
              const SizedBox(height: 24),
              Text('${routine.title} complete!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('You finished all ${_steps.length} steps. Nice work.', style: const TextStyle(color: AppColors.lightTextSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AppButton(label: 'Done', color: color, onPressed: () => Navigator.of(context).pop()),
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
