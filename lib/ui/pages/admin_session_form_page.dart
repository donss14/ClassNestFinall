
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../models/subject.dart';
import '../../services/firestore_service.dart';
import '../organisms/session_form.dart';

class AdminSessionFormPage extends StatefulWidget {
  const AdminSessionFormPage({
    super.key,
    required this.studentId,
    required this.studentEmail,
    this.initial,
  });

  final String studentId;
  final String studentEmail;
  final ClassSession? initial;

  @override
  State<AdminSessionFormPage> createState() =>
      _AdminSessionFormPageState();
}

class _AdminSessionFormPageState
    extends State<AdminSessionFormPage> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _subjectsFuture = context.read<FirestoreService>().getSubjects(
          studentId: widget.studentId,
        );
  }

  Future<void> _save(ClassSession session) async {
    setState(() => _saving = true);

    final firestore = context.read<FirestoreService>();

    try {
      final conflict = await firestore.hasScheduleConflict(
        studentId: widget.studentId,
        dayOfWeek: session.dayOfWeek,
        startMinutes: session.startMinutes,
        endMinutes: session.endMinutes,
        excludeScheduleId: session.id,
      );

      if (conflict) {
        throw Exception(
          'This time overlaps another class on that day.',
        );
      }

      await firestore.saveSchedule(
        id: session.id,
        data: session.toMap(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initial == null
                ? 'Student schedule added successfully.'
                : 'Student schedule updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.contains('overlaps')
                ? message
                : 'Could not save the schedule. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null
              ? 'Add Student Schedule'
              : 'Edit Student Schedule',
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load student subjects.'),
            );
          }

          final subjects = (snapshot.data ?? [])
              .map(
                (map) => Subject.fromMap(
                  map,
                  id: map['id'] as String,
                ),
              )
              .toList();

          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This student has no registered subjects. '
                  'Add a subject for this student first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Student: ${widget.studentEmail}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              SessionForm(
                subjects: subjects,
                initial: widget.initial,
                studentId: widget.studentId,
                isSaving: _saving,
                onSubmit: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}
