import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task_item.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common_widgets.dart';

class CreateTaskScreen extends StatefulWidget {
  final TaskItem? existing;
  const CreateTaskScreen({super.key, this.existing});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _category = TextEditingController(text: widget.existing?.category ?? 'General');
  late TaskPriority _priority = widget.existing?.priority ?? TaskPriority.medium;
  DateTime? _dueDate = widget.existing?.dueDate ?? DateTime.now();
  TimeOfDay? _dueTime = widget.existing?.dueHour != null
      ? TimeOfDay(hour: widget.existing!.dueHour!, minute: widget.existing!.dueMinute!)
      : null;
  late bool _reminderEnabled = widget.existing?.reminderEnabled ?? false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<TaskProvider>();

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          dueTime: _dueTime != null
              ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}:00'
              : null,
          reminderEnabled: _reminderEnabled,
        );
        await provider.updateTask(updated);
      } else {
        await provider.createTask(
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          dueHour: _dueTime?.hour,
          dueMinute: _dueTime?.minute,
          reminderEnabled: _reminderEnabled,
        );
      }
      if (!mounted) return;
      showAppSnackBar(context, _isEditing ? 'Task updated' : 'Task created');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: 'This will permanently remove "${widget.existing!.title}".',
      confirmLabel: 'Delete',
    );
    if (!confirm) return;
    await context.read<TaskProvider>().deleteTask(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Color get _priorityColor => switch (_priority) {
        TaskPriority.high => AppColors.error,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteTask),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              AppTextField(
                controller: _title,
                label: 'Task title',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a task title' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _description,
                label: 'Description (optional)',
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              AppTextField(controller: _category, label: 'Category'),
              const SizedBox(height: 20),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: TaskPriority.values.map((p) {
                  final labels = {TaskPriority.low: 'Low', TaskPriority.medium: 'Medium', TaskPriority.high: 'High'};
                  final colors = {TaskPriority.low: AppColors.info, TaskPriority.medium: AppColors.warning, TaskPriority.high: AppColors.error};
                  final selected = _priority == p;
                  return ChoiceChip(
                    label: Text(labels[p]!),
                    selected: selected,
                    selectedColor: colors[p]!.withOpacity(0.16),
                    labelStyle: TextStyle(color: selected ? colors[p] : null, fontWeight: selected ? FontWeight.w700 : null),
                    onSelected: (_) => setState(() => _priority = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              AppCard(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: _priorityColor),
                    const SizedBox(width: 12),
                    const Text('Due date'),
                    const Spacer(),
                    Text(_dueDate != null ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}' : 'None'),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _dueTime ?? TimeOfDay.now());
                  if (picked != null) setState(() => _dueTime = picked);
                },
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 18, color: _priorityColor),
                    const SizedBox(width: 12),
                    const Text('Due time'),
                    const Spacer(),
                    Text(_dueTime != null ? _dueTime!.format(context) : 'None'),
                    if (_dueTime != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() => _dueTime = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder'),
                  subtitle: Text(_reminderEnabled ? 'You will be notified at the due date/time' : 'Off'),
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                ),
              ),
              const SizedBox(height: 28),
              AppButton(label: _isEditing ? 'Save Changes' : 'Create Task', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
