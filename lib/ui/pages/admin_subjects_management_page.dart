
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/subject.dart';
import '../../services/firestore_service.dart';
import '../organisms/subject_form.dart';

class AdminSubjectsManagementPage extends StatefulWidget {
  const AdminSubjectsManagementPage({super.key});

  @override
  State<AdminSubjectsManagementPage> createState() =>
      _AdminSubjectsManagementPageState();
}

class _AdminSubjectsManagementPageState
    extends State<AdminSubjectsManagementPage> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    _studentsFuture = context.read<FirestoreService>().getStudents();
  }

  Future<void> _refresh() async {
    setState(_loadStudents);
    await _studentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load students: ${snapshot.error}'),
            );
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return const Center(
              child: Text('No registered students found.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final studentId = student['id'] as String;
                final email =
                    student['email'] as String? ?? 'No email';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(email),
                    subtitle: const Text('Manage this student’s subjects'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminStudentSubjectsPage(
                            studentId: studentId,
                            studentEmail: email,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminStudentSubjectsPage extends StatefulWidget {
  const AdminStudentSubjectsPage({
    super.key,
    required this.studentId,
    required this.studentEmail,
  });

  final String studentId;
  final String studentEmail;

  @override
  State<AdminStudentSubjectsPage> createState() =>
      _AdminStudentSubjectsPageState();
}

class _AdminStudentSubjectsPageState
    extends State<AdminStudentSubjectsPage> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;

  FirestoreService get _firestore =>
      context.read<FirestoreService>();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    _subjectsFuture = _firestore.getSubjects(
      studentId: widget.studentId,
    );
  }

  Future<void> _refresh() async {
    setState(_loadSubjects);
    await _subjectsFuture;
  }

  Future<void> _openEditor({Subject? subject}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminSubjectEditorPage(
          studentId: widget.studentId,
          initial: subject,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(_loadSubjects);
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    if (subject.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          'Are you sure you want to delete ${subject.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _firestore.deleteSubject(subject.id!);

      if (!mounted) return;

      setState(_loadSubjects);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject deleted.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete subject: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Subjects'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.studentEmail,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Manage the subjects assigned to this student.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _subjectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load subjects: ${snapshot.error}'),
                  );
                }

                final subjects = (snapshot.data ?? [])
                    .map(
                      (map) => Subject.fromMap(
                        map,
                        id: map['id'] as String?,
                      ),
                    )
                    .toList();

                if (subjects.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'This student has no subjects yet.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(subject.colorValue),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(subject.name),
                          subtitle: Text(
                            '${subject.code}\n'
                            '${subject.instructor ?? 'No instructor assigned'}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openEditor(subject: subject);
                              } else if (value == 'delete') {
                                _deleteSubject(subject);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSubjectEditorPage extends StatefulWidget {
  const _AdminSubjectEditorPage({
    required this.studentId,
    this.initial,
  });

  final String studentId;
  final Subject? initial;

  @override
  State<_AdminSubjectEditorPage> createState() =>
      _AdminSubjectEditorPageState();
}

class _AdminSubjectEditorPageState
    extends State<_AdminSubjectEditorPage> {
  bool _saving = false;

  Future<void> _save(Subject subject) async {
    setState(() => _saving = true);

    try {
      await context.read<FirestoreService>().saveSubject(
        id: subject.id,
        data: {
          ...subject.toMap(),
          'studentId': widget.studentId,
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save subject: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Add Subject' : 'Edit Subject',
        ),
      ),
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
