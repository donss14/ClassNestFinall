import 'package:flutter/material.dart';

import '../../core/constants/subject_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/subject.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text_field.dart';
import '../molecules/subject_color_picker.dart';

class SubjectForm extends StatefulWidget {
  const SubjectForm({
    super.key,
    this.initial,
    required this.onSubmit,
    this.isSaving = false,
  });

  final Subject? initial;
  final void Function(Subject subject) onSubmit;
  final bool isSaving;

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _instructor;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _code = TextEditingController(text: s?.code ?? '');
    _name = TextEditingController(text: s?.name ?? '');
    _instructor = TextEditingController(text: s?.instructor ?? '');
    _colorValue = s?.colorValue ?? subjectColorValues.first;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _instructor.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final instructor = _instructor.text.trim();
    widget.onSubmit(Subject(
      id: widget.initial?.id,
      code: _code.text.trim(),
      name: _name.text.trim(),
      instructor: instructor.isEmpty ? null : instructor,
      colorValue: _colorValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _code,
            label: 'Subject code (e.g., CC105)',
            icon: Icons.tag,
            validator: Validators.subjectCode,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _name,
            label: 'Subject name',
            icon: Icons.menu_book_outlined,
            validator: Validators.subjectName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _instructor,
            label: 'Instructor (optional)',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SubjectColorPicker(
            selectedValue: _colorValue,
            onChanged: (v) => setState(() => _colorValue = v),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: widget.initial == null ? 'Add subject' : 'Save changes',
            icon: Icons.check,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
