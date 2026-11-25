import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/subject.dart';
import '../../providers/schedule_provider.dart';
import '../molecules/confirm_dialog.dart';
import '../molecules/empty_state.dart';
import '../organisms/subject_tile.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  Future<void> _delete(BuildContext context, Subject subject) async {
    final provider = context.read<ScheduleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Delete ${subject.code}?',
      message: 'This also removes all of its scheduled classes.',
    );
    if (!ok) return;
    final error = await provider.deleteSubject(subject.id!);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.subjects.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        message: 'Tap "Add subject" to create your first one.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: provider.subjects.length,
      itemBuilder: (context, i) {
        final subject = provider.subjects[i];
        return SubjectTile(
          subject: subject,
          classCount: provider.sessionCountFor(subject.id!),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.subjectForm,
            arguments: subject,
          ),
          onDelete: () => _delete(context, subject),
        );
      },
    );
  }
}
