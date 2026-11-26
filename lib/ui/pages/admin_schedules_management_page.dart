
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_session.dart';
import '../../services/firestore_service.dart';
import 'admin_schedule_data.dart';
import 'admin_session_form_page.dart';

class AdminSchedulesManagementPage extends StatefulWidget {
  const AdminSchedulesManagementPage({super.key});

  @override
  State<AdminSchedulesManagementPage> createState() =>
      _AdminSchedulesManagementPageState();
}

class _AdminSchedulesManagementPageState
    extends State<AdminSchedulesManagementPage> {
  late final FirestoreService _firestore;
  late Future<AdminScheduleData> _dataFuture;

  String _selectedStudentId = 'all';

  @override
  void initState() {
    super.initState();
    _firestore = context.read<FirestoreService>();
    _loadData();
  }

  void _loadData() {
    _dataFuture = AdminScheduleData.load(_firestore);
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await _dataFuture;
  }

  String _dayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (day < 1 || day > 7) return 'Unknown day';
    return days[day - 1];
  }

  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _searchStudent(AdminScheduleData data) async {
    final selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredStudents = data.students.where((student) {
              final email =
                  student['email'] as String? ?? '';

              return email.toLowerCase().contains(
                    searchQuery.trim().toLowerCase(),
                  );
            }).toList();

            return AlertDialog(
              title: const Text('Search student'),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter student email...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.people),
                            title: const Text('All students'),
                            selected: _selectedStudentId == 'all',
                            onTap: () {
                              Navigator.pop(dialogContext, 'all');
                            },
                          ),
                          const Divider(),
                          if (filteredStudents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No students found.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...filteredStudents.map((student) {
                              final id = student['id'] as String;
                              final email =
                                  student['email'] as String? ??
                                      'Unknown student';

                              return ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(
                                  email,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: _selectedStudentId == id,
                                onTap: () {
                                  Navigator.pop(dialogContext, id);
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selectedId == null) return;

    setState(() {
      _selectedStudentId = selectedId;
    });
  }

  Future<void> _openAddSchedule(AdminScheduleData data) async {
    String? studentId;

    if (_selectedStudentId != 'all') {
      studentId = _selectedStudentId;
    } else {
      studentId = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            title: const Text('Select a student'),
            children: data.students.map((student) {
              final id = student['id'] as String;
              final email =
                  student['email'] as String? ?? 'Unknown student';

              return SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, id),
                child: Text(email),
              );
            }).toList(),
          );
        },
      );
    }

    if (!mounted || studentId == null) return;

    final studentEmail = data.studentEmail(studentId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSessionFormPage(
          studentId: studentId!,
          studentEmail: studentEmail,
        ),
      ),
    );

    if (mounted) {
      setState(_loadData);
    }
  }

  Future<void> _openEditSchedule(
    Map<String, dynamic> schedule,
    AdminScheduleData data,
  ) async {
    final scheduleId = schedule['id'] as String?;
    final studentId = schedule['studentId'] as String?;

    if (scheduleId == null || studentId == null) return;

    final session = ClassSession.fromMap(
      schedule,
      id: scheduleId,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSessionFormPage(
          studentId: studentId,
          studentEmail: data.studentEmail(studentId),
          initial: session,
        ),
      ),
    );

    if (mounted) {
      setState(_loadData);
    }
  }

  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    final scheduleId = schedule['id'] as String?;
    if (scheduleId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete schedule?'),
          content: const Text(
            'Are you sure you want to delete this schedule?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _firestore.deleteSchedule(scheduleId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule deleted successfully.'),
        ),
      );

      setState(_loadData);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete schedule: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Management'),
      ),
      floatingActionButton: FutureBuilder<AdminScheduleData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: () => _openAddSchedule(snapshot.data!),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: FutureBuilder<AdminScheduleData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load schedules: ${snapshot.error}',
                ),
              ),
            );
          }

          final data = snapshot.data!;

          final filteredSchedules = data.schedules.where((schedule) {
            if (_selectedStudentId == 'all') return true;
            return schedule['studentId'] == _selectedStudentId;
          }).toList();

          filteredSchedules.sort((a, b) {
            final dayComparison =
                (a['dayOfWeek'] as int).compareTo(
              b['dayOfWeek'] as int,
            );

            if (dayComparison != 0) return dayComparison;

            return (a['startMinutes'] as int).compareTo(
              b['startMinutes'] as int,
            );
          });

          final selectedStudentEmail = _selectedStudentId == 'all'
              ? 'All students'
              : data.studentEmail(_selectedStudentId);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStudentId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter by student',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All students'),
                          ),
                          ...data.students.map((student) {
                            final id = student['id'] as String;
                            final email =
                                student['email'] as String? ??
                                    'Unknown student';

                            return DropdownMenuItem(
                              value: id,
                              child: Text(
                                email,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStudentId = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Search student by email',
                      onPressed: () => _searchStudent(data),
                      icon: const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $selectedStudentEmail',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  '${filteredSchedules.length} schedule(s)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (filteredSchedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No schedules found.'),
                    ),
                  )
                else
                  ...filteredSchedules.map((schedule) {
                    final studentId =
                        schedule['studentId'] as String?;
                    final day =
                        schedule['dayOfWeek'] as int? ?? 0;
                    final start =
                        schedule['startMinutes'] as int? ?? 0;
                    final end =
                        schedule['endMinutes'] as int? ?? 0;
                    final room =
                        schedule['room'] as String? ??
                            'No room assigned';

                    final studentEmail = studentId == null
                        ? 'Unknown student'
                        : data.studentEmail(studentId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          '${data.subjectCode(schedule)} ${data.subjectName(schedule)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(studentEmail),
                              Text(_dayName(day)),
                              Text(
                                '${_formatTime(start)} - ${_formatTime(end)}',
                              ),
                              Text('Room: $room'),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _openEditSchedule(schedule, data);
                            } else if (action == 'delete') {
                              _deleteSchedule(schedule);
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
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
