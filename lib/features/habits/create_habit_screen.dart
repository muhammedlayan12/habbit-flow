import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common_widgets.dart';

class CreateHabitScreen extends StatefulWidget {
  final Habit? existing;
  const CreateHabitScreen({super.key, this.existing});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _targetUnit = TextEditingController(text: widget.existing?.targetUnit ?? '1 time');
  late final _category = TextEditingController(text: widget.existing?.category ?? 'General');

  late String _iconKey = widget.existing?.iconKey ?? HabitIcons.keys.first;
  late int _colorIndex = widget.existing?.colorIndex ?? 0;
  late HabitFrequencyType _frequencyType = widget.existing?.frequency.type ?? HabitFrequencyType.daily;
  late List<int> _customDays = List<int>.from(widget.existing?.frequency.customDays ?? []);
  late bool _reminderEnabled = widget.existing?.reminderEnabled ?? false;
  TimeOfDay? _reminderTime = widget.existing?.reminderHour != null
      ? TimeOfDay(hour: widget.existing!.reminderHour!, minute: widget.existing!.reminderMinute!)
      : const TimeOfDay(hour: 8, minute: 0);
  late DateTime _startDate = widget.existing?.startDate ?? DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _targetUnit.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequencyType == HabitFrequencyType.custom && _customDays.isEmpty) {
      showAppSnackBar(context, 'Select at least one day for a custom frequency', isError: true);
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    final frequency = HabitFrequency(type: _frequencyType, customDays: _customDays);
    final targetValue =
        int.tryParse(RegExp(r'\d+').firstMatch(_targetUnit.text)?.group(0) ?? '1') ?? 1;

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          iconKey: _iconKey,
          colorIndex: _colorIndex,
          frequency: frequency,
          targetUnit: _targetUnit.text.trim(),
          targetValue: targetValue,
          reminderEnabled: _reminderEnabled,
          reminderTime: _reminderEnabled && _reminderTime != null
              ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}:00'
              : null,
          startDate: _startDate,
        );
        await provider.updateHabit(updated);
      } else {
        await provider.createHabit(
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          iconKey: _iconKey,
          colorIndex: _colorIndex,
          frequency: frequency,
          targetUnit: _targetUnit.text.trim(),
          targetValue: targetValue,
          reminderEnabled: _reminderEnabled,
          reminderHour: _reminderEnabled ? _reminderTime?.hour : null,
          reminderMinute: _reminderEnabled ? _reminderTime?.minute : null,
          startDate: _startDate,
        );
      }
      if (!mounted) return;
      showAppSnackBar(context, _isEditing ? 'Habit updated' : 'Habit created');
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Habit' : 'Create Habit')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              AppTextField(
                controller: _title,
                label: 'Habit name',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a habit name' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _description,
                label: 'Description (optional)',
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              AppTextField(controller: _category, label: 'Category'),
              const SizedBox(height: 20),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: HabitIcons.keys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final key = HabitIcons.keys[i];
                    final selected = _iconKey == key;
                    final color = AppColors.colorForIndex(_colorIndex);
                    return GestureDetector(
                      onTap: () => setState(() => _iconKey = key),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.16) : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? color : AppColors.lightBorder, width: selected ? 2 : 1),
                        ),
                        child: Icon(HabitIcons.byKey[key], color: selected ? color : AppColors.lightTextSecondary),
                      ),
                    );
                  },
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
              const SizedBox(height: 20),
              AppTextField(
                controller: _targetUnit,
                label: 'Target (e.g. 20 minutes, 8 glasses, 10 pages)',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a target' : null,
              ),
              const SizedBox(height: 20),
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: HabitFrequencyType.values.map((type) {
                  final labels = {
                    HabitFrequencyType.daily: 'Every day',
                    HabitFrequencyType.weekdays: 'Weekdays',
                    HabitFrequencyType.weekends: 'Weekends',
                    HabitFrequencyType.custom: 'Custom days',
                  };
                  return ChoiceChip(
                    label: Text(labels[type]!),
                    selected: _frequencyType == type,
                    onSelected: (_) => setState(() => _frequencyType = type),
                  );
                }).toList(),
              ),
              if (_frequencyType == HabitFrequencyType.custom) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final selected = _customDays.contains(day);
                    return FilterChip(
                      label: Text(names[i]),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v ? _customDays.add(day) : _customDays.remove(day);
                      }),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder'),
                      subtitle: Text(_reminderEnabled && _reminderTime != null
                          ? 'Daily at ${_reminderTime!.format(context)}'
                          : 'Off'),
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                    if (_reminderEnabled)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: _reminderTime ?? TimeOfDay.now());
                            if (picked != null) setState(() => _reminderTime = picked);
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 18),
                          label: const Text('Change time'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Text('Start date'),
                    const Spacer(),
                    Text('${_startDate.month}/${_startDate.day}/${_startDate.year}'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton(label: _isEditing ? 'Save Changes' : 'Create Habit', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
