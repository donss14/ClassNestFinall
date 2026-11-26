
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../services/firestore_service.dart';
import 'admin_schedule_data.dart';
import 'admin_session_form_page.dart';

class AdminRoomManagementPage extends StatefulWidget {
  const AdminRoomManagementPage({super.key});

  @override
  State<AdminRoomManagementPage> createState() =>
      _AdminRoomManagementPageState();
}

class _AdminRoomManagementPageState
    extends State<AdminRoomManagementPage> {
  late Future<AdminScheduleData> _dataFuture;

  FirestoreService get _firestore =>
      context.read<FirestoreService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dataFuture = AdminScheduleData.load(_firestore);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _dataFuture;
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

  Future<void> _editSchedule(
    Map<String, dynamic> schedule,
    AdminScheduleData data,
  ) async {
    final studentId = schedule['studentId'] as String?;
    final scheduleId = schedule['id'] as String?;

    if (studentId == null || scheduleId == null) return;

    final session = ClassSession.fromMap(
      schedule,
      id: scheduleId,
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSessionFormPage(
          studentId: studentId,
          studentEmail: data.studentEmail(studentId),
          initial: session,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(_load);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
      ),
      body: FutureBuilder<AdminScheduleData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load room assignments: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;

          final rooms = <String, List<Map<String, dynamic>>>{};

          for (final schedule in data.schedules) {
            final room = (schedule['room'] as String? ?? '').trim();
            final roomName =
                room.isEmpty ? 'No room assigned' : room;

            rooms.putIfAbsent(roomName, () => []).add(schedule);
          }

          final roomNames = rooms.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${roomNames.length} room group(s)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (roomNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text('No classroom assignments found.'),
                    ),
                  ),
                ...roomNames.map((roomName) {
                  final roomSchedules = rooms[roomName]!;

                  roomSchedules.sort((a, b) {
                    final dayA = a['dayOfWeek'] as int? ?? 0;
                    final dayB = b['dayOfWeek'] as int? ?? 0;

                    if (dayA != dayB) return dayA.compareTo(dayB);

                    final startA = a['startMinutes'] as int? ?? 0;
                    final startB = b['startMinutes'] as int? ?? 0;

                    return startA.compareTo(startB);
                  });

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      leading: const Icon(Icons.meeting_room),
                      title: Text(
                        roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${roomSchedules.length} scheduled class(es)',
                      ),
                      children: roomSchedules.map((schedule) {
                        final studentId =
                            schedule['studentId'] as String? ?? '';

                        final start =
                            _formatTime(schedule['startMinutes']);
                        final end =
                            _formatTime(schedule['endMinutes']);

                        return ListTile(
                          title: Text(data.subjectName(schedule)),
                          subtitle: Text([
                            data.studentEmail(studentId),
                            _dayName(schedule['dayOfWeek']),
                            '$start - $end',
                          ].join('\n')),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'Edit room assignment',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              _editSchedule(schedule, data);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
