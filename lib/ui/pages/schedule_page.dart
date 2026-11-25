import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/utils/time_utils.dart';
import '../../models/class_session.dart';
import '../../providers/schedule_provider.dart';
import '../molecules/confirm_dialog.dart';
import '../molecules/day_selector.dart';
import '../molecules/empty_state.dart';
import '../organisms/class_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _day = DateTime.now().weekday;

  void _showMessage(String? error) {
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _delete(ClassSession session) async {
    final provider = context.read<ScheduleProvider>();
    final ok = await confirmDelete(
      context,
      title: 'Delete class?',
      message: 'This removes the class from your schedule.',
    );
    if (!ok) return;
    _showMessage(await provider.deleteSession(session.id!));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: provider.errorMessage!,
      );
    }
    if (provider.subjects.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        message: 'Open the Subjects tab and add your first subject, '
            'then schedule its classes here.',
      );
    }

    final sessions = provider.sessionsForDay(_day);
    final isToday = _day == DateTime.now().weekday;

    return Column(
      children: [
        const SizedBox(height: 8),
        DaySelector(
            selectedDay: _day, onChanged: (d) => setState(() => _day = d)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isToday
                  ? '${TimeUtils.dayName(_day)} (Today)'
                  : TimeUtils.dayName(_day),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Expanded(
          child: sessions.isEmpty
              ? EmptyState(
                  icon: Icons.free_breakfast_outlined,
                  title: 'No classes on ${TimeUtils.dayName(_day)}',
                  message: 'Tap "Add class" to schedule one.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final session = sessions[i];
                    final subject = provider.subjectById(session.subjectId);
                    if (subject == null) return const SizedBox.shrink();
                    return ClassCard(
                      subject: subject,
                      session: session,
                      onEdit: () => Navigator.pushNamed(
                        context,
                        AppRoutes.sessionForm,
                        arguments: session,
                      ),
                      onDelete: () => _delete(session),
                      onDismissChange: () async => _showMessage(
                          await provider.dismissRoomChange(session.id!)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
