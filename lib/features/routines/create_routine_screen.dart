import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common_widgets.dart';

class CreateRoutineScreen extends StatefulWidget {
  final Routine? existing;
  const CreateRoutineScreen({super.key, this.existing});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _StepDraft {
  String title;
  int durationSeconds;
  String notes;
  _StepDraft({required this.title, this.durationSeconds = 300, this.notes = ''});
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late TimeOfDay _startTime = widget.existing != null
      ? TimeOfDay(hour: widget.existing!.startHour, minute: widget.existing!.startMinute)
      : const TimeOfDay(hour: 7, minute: 0);
  late int _colorIndex = widget.existing?.colorIndex ?? 0;
  List<_StepDraft> _steps = [];
  bool _saving = false;
  bool _loadingSteps = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final steps = context.read<RoutineProvider>().stepsFor(widget.existing!.id);
      _steps = steps
          .map((s) => _StepDraft(title: s.title, durationSeconds: s.durationSeconds, notes: s.notes))
          .toList();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (ctx) => _StepEditorDialog(
        onSave: (draft) => setState(() => _steps.add(draft)),
      ),
    );
  }

  void _editStep(int index) {
    showDialog(
      context: context,
      builder: (ctx) => _StepEditorDialog(
        initial: _steps[index],
        onSave: (draft) => setState(() => _steps[index] = draft),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      showAppSnackBar(context, 'Add at least one step', isError: true);
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<RoutineProvider>();

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          startTime:
              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
          colorIndex: _colorIndex,
        );
        await provider.updateRoutine(updated);
        await provider.replaceSteps(
          updated.id,
          _steps
              .asMap()
              .entries
              .map((e) => RoutineStep(
                    id: '',
                    routineId: updated.id,
                    title: e.value.title,
                    durationSeconds: e.value.durationSeconds,
                    order: e.key,
                    notes: e.value.notes,
                  ))
              .toList(),
        );
      } else {
        await provider.createRoutine(
          title: _title.text.trim(),
          description: _description.text.trim(),
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          colorIndex: _colorIndex,
          steps: _steps
              .map((s) => RoutineStep(
                    id: '',
                    routineId: '',
                    title: s.title,
                    durationSeconds: s.durationSeconds,
                    order: 0,
                    notes: s.notes,
                  ))
              .toList(),
        );
      }
      if (!mounted) return;
      showAppSnackBar(context, _isEditing ? 'Routine updated' : 'Routine created');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForIndex(_colorIndex);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Routine' : 'Create Routine')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              AppTextField(
                controller: _title,
                label: 'Routine name',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a routine name' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _description,
                label: 'Description (optional)',
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              AppCard(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Start time'),
                    const Spacer(),
                    Text(_startTime.format(context)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColors.categoryPalette.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final selected = _colorIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _colorIndex = i),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.colorForIndex(i),
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: Colors.black.withOpacity(0.3), width: 2.5) : null,
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Steps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  TextButton.icon(onPressed: _addStep, icon: const Icon(Icons.add, size: 18), label: const Text('Add step')),
                ],
              ),
              const SizedBox(height: 8),
              if (_steps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No steps yet. Add your first step above.', style: TextStyle(color: AppColors.lightTextSecondary)),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _steps.removeAt(oldIndex);
                      _steps.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Padding(
                      key: ValueKey('step_$index${step.title}'),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        onTap: () => _editStep(index),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator_rounded, color: AppColors.lightTextSecondary),
                            const SizedBox(width: 8),
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(8)),
                              child: Text('${index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(step.title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            ),
                            Text('${(step.durationSeconds / 60).ceil()} min', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _steps.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),
              AppButton(label: _isEditing ? 'Save Changes' : 'Create Routine', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepEditorDialog extends StatefulWidget {
  final _StepDraft? initial;
  final ValueChanged<_StepDraft> onSave;
  const _StepEditorDialog({this.initial, required this.onSave});

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late int _minutes = ((widget.initial?.durationSeconds ?? 300) / 60).round().clamp(1, 120);

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Step' : 'Edit Step'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: _title, label: 'Step title', textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 16),
            AppTextField(controller: _notes, label: 'Notes (optional)', maxLines: 2),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Duration'),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _minutes = (_minutes - 1).clamp(1, 120)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_minutes min', style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => setState(() => _minutes = (_minutes + 1).clamp(1, 120)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            widget.onSave(_StepDraft(
              title: _title.text.trim(),
              durationSeconds: _minutes * 60,
              notes: _notes.text.trim(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
