import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/subject.dart';
import '../../providers/schedule_provider.dart';
import '../organisms/subject_form.dart';
import '../templates/page_template.dart';

/// Add a subject, or edit one when [initial] is given.
class SubjectFormPage extends StatefulWidget {
  const SubjectFormPage({super.key, this.initial});

  final Subject? initial;

  @override
  State<SubjectFormPage> createState() => _SubjectFormPageState();
}

class _SubjectFormPageState extends State<SubjectFormPage> {
  bool _saving = false;

  Future<void> _save(Subject subject) async {
    setState(() => _saving = true);
    final error = await context.read<ScheduleProvider>().saveSubject(subject);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: widget.initial == null ? 'Add subject' : 'Edit subject',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SubjectForm(
          initial: widget.initial,
          isSaving: _saving,
          onSubmit: _save,
        ),
      ),
    );
  }
}
