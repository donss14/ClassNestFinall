
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import 'admin_session_form_page.dart';

class StudentDetailsPage extends StatefulWidget {
  const StudentDetailsPage({
    super.key,
    required this.studentId,
    required this.email,
  });

  final String studentId;
  final String email;

  @override
  State<StudentDetailsPage> createState() =>
      _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;
  late Future<List<Map<String, dynamic>>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    final firestore = context.read<FirestoreService>();

    _subjectsFuture = firestore.getSubjects(
      studentId: widget.studentId,
    );

    _schedulesFuture = firestore.getSchedules(
      studentId: widget.studentId,
    );
  }

  Future<void> _refresh() async {
    setState(_loadDetails);

    await Future.wait([
      _subjectsFuture,
      _schedulesFuture,
    ]);
  }

  Future<void> _openAddSchedule() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSessionFormPage(
          studentId: widget.studentId,
          studentEmail: widget.email,
        ),
      ),
    );

    if (result == true && mounted) {
      await _refresh();
    }
  }

  String _dayName(dynamic value) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (value is! int || value < 1 || value > 7) {
      return 'Unknown day';
    }

    return days[value - 1];
  }

  String _formatTime(dynamic value) {
    if (value is! int || value < 0 || value >= 1440) {
      return '--:--';
    }

    final hour = value ~/ 60;
    final minute = value % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSchedule,
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(widget.email),
                subtitle: const Text('Student Account'),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Registered Subjects',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _subjectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Text('Could not load subjects.');
                }

                final subjects = snapshot.data ?? [];

                if (subjects.isEmpty) {
                  return const Text('No subjects registered.');
                }

                return Column(
                  children: subjects.map((subject) {
                    final name = subject['name'] as String? ??
                        'Unnamed Subject';

                    final code = subject['code'] as String? ??
                        'No code';

                    final instructor =
                        subject['instructor'] as String?;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text(name),
                        subtitle: Text(
                          instructor == null || instructor.isEmpty
                              ? code
                              : '$code • $instructor',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Class Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _schedulesFuture,
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (scheduleSnapshot.hasError) {
                  return const Text('Could not load schedules.');
                }

                final schedules = scheduleSnapshot.data ?? [];

                if (schedules.isEmpty) {
                  return const Text('No schedules registered.');
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _subjectsFuture,
                  builder: (context, subjectSnapshot) {
                    if (subjectSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (subjectSnapshot.hasError) {
                      return const Text(
                        'Could not match schedule subjects.',
                      );
                    }

                    final subjects = subjectSnapshot.data ?? [];

                    final subjectMap = {
                      for (final subject in subjects)
                        if (subject['id'] is String)
                          subject['id'] as String: subject,
                    };

                    schedules.sort((a, b) {
                      final dayA = a['dayOfWeek'] as int? ?? 0;
                      final dayB = b['dayOfWeek'] as int? ?? 0;

                      if (dayA != dayB) {
                        return dayA.compareTo(dayB);
                      }

                      final startA =
                          a['startMinutes'] as int? ?? 0;
                      final startB =
                          b['startMinutes'] as int? ?? 0;

                      return startA.compareTo(startB);
                    });

                    return Column(
                      children: schedules.map((schedule) {
                        final subjectId =
                            schedule['subjectId'] as String?;

                        final subject = subjectId == null
                            ? null
                            : subjectMap[subjectId];

                        final subjectName =
                            subject?['name'] as String? ??
                                'Unknown Subject';

                        final subjectCode =
                            subject?['code'] as String? ?? '';

                        final room =
                            schedule['room'] as String? ??
                                'No room assigned';

                        final day = _dayName(
                          schedule['dayOfWeek'],
                        );

                        final start = _formatTime(
                          schedule['startMinutes'],
                        );

                        final end = _formatTime(
                          schedule['endMinutes'],
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_month,
                            ),
                            title: Text(subjectName),
                            subtitle: Text(
                              [
                                if (subjectCode.isNotEmpty)
                                  subjectCode,
                                day,
                                '$start - $end',
                                'Room: $room',
                              ].join('\n'),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
