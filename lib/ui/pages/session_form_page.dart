import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../providers/schedule_provider.dart';
import '../molecules/empty_state.dart';
import '../organisms/session_form.dart';
import '../templates/page_template.dart';

/// Add a class, or edit one when [initial] is given.
class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key, this.initial});

  final ClassSession? initial;

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  bool _saving = false;

  Future<void> _save(ClassSession session) async {
    setState(() => _saving = true);
    final error = await context.read<ScheduleProvider>().saveSession(session);
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
    final subjects = context.watch<ScheduleProvider>().subjects;

    return PageTemplate(
      title: widget.initial == null ? 'Add class' : 'Edit class',
      body: subjects.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Add a subject first',
              message: 'Classes belong to a subject. Create one in the '
                  'Subjects tab, then come back.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SessionForm(
                subjects: subjects,
                initial: widget.initial,
                isSaving: _saving,
                onSubmit: _save,
              ),
            ),
    );
  }
}
