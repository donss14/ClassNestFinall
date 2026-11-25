import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../models/class_session.dart';
import '../../models/subject.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text_field.dart';
import '../molecules/day_selector.dart';
import '../molecules/subject_picker.dart';
import '../molecules/time_field.dart';

class SessionForm extends StatefulWidget {
  const SessionForm({
    super.key,
    required this.subjects,
    this.initial,
    required this.onSubmit,
    this.isSaving = false,
  });

  final List<Subject> subjects;
  final ClassSession? initial;
  final void Function(ClassSession session) onSubmit;
  final bool isSaving;

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _room;
  int? _subjectId;
  late int _day;
  late int _start;
  late int _end;
  String? _subjectError;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _room = TextEditingController(text: s?.room ?? '');
    _subjectId = s?.subjectId;
    _day = s?.dayOfWeek ?? DateTime.now().weekday;
    _start = s?.startMinutes ?? 8 * 60;
    _end = s?.endMinutes ?? 9 * 60 + 30;
  }

  @override
  void dispose() {
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = minutes;
      } else {
        _end = minutes;
      }
      _timeError = null;
    });
  }

  void _submit() {
    final fieldsValid = _formKey.currentState!.validate();
    final subjectError = _subjectId == null ? 'Choose a subject' : null;
    final timeError = Validators.timeRange(_start, _end);
    setState(() {
      _subjectError = subjectError;
      _timeError = timeError;
    });
    if (!fieldsValid || subjectError != null || timeError != null) return;

    final initial = widget.initial;
    widget.onSubmit(ClassSession(
      id: initial?.id,
      subjectId: _subjectId!,
      dayOfWeek: _day,
      startMinutes: _start,
      endMinutes: _end,
      room: _room.text.trim(),
      previousRoom: initial?.previousRoom,
      roomChangedAtMillis: initial?.roomChangedAtMillis,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubjectPicker(
            subjects: widget.subjects,
            selectedId: _subjectId,
            errorText: _subjectError,
            onChanged: (id) => setState(() {
              _subjectId = id;
              _subjectError = null;
            }),
          ),
          const SizedBox(height: 20),
          Text('Day', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: DaySelector(
              selectedDay: _day,
              onChanged: (d) => setState(() => _day = d),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TimeField(
                  label: 'Start',
                  minutes: _start,
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TimeField(
                  label: 'End',
                  minutes: _end,
                  errorText: _timeError,
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _room,
            label: 'Room (e.g., Room 204)',
            icon: Icons.meeting_room_outlined,
            validator: Validators.room,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 28),
          AppButton(
            label: widget.initial == null ? 'Add class' : 'Save changes',
            icon: Icons.check,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
