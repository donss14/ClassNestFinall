
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

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStudentId = 'all';
  String _selectedYear = 'All Years';
  String _selectedCourse = 'All Courses';

  final List<String> _yearOptions = [
    'All Years',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  @override
  void initState() {
    super.initState();
    _firestore = context.read<FirestoreService>();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Map<String, dynamic>? _studentForSchedule(
    Map<String, dynamic> schedule,
    AdminScheduleData data,
  ) {
    final studentId = schedule['studentId'] as String?;

    if (studentId == null) return null;

    for (final student in data.students) {
      if (student['id'] == studentId) {
        return student;
      }
    }

    return null;
  }

  List<String> _getCourseOptions(AdminScheduleData data) {
    final courses = data.students
        .map((student) => student['course'] as String? ?? '')
        .where((course) => course.trim().isNotEmpty)
        .toSet()
        .toList();

    courses.sort();

    return ['All Courses', ...courses];
  }

  bool _matchesStudentFilters(
    Map<String, dynamic> schedule,
    AdminScheduleData data,
  ) {
    final student = _studentForSchedule(schedule, data);

    if (student == null) return false;

    final search = _searchController.text.trim().toLowerCase();

    final name =
        (student['name'] as String? ?? '').toLowerCase();

    final email =
        (student['email'] as String? ?? '').toLowerCase();

    final year = student['year'] as String? ?? '';
    final course = student['course'] as String? ?? '';

    final matchesSearch = search.isEmpty ||
        name.contains(search) ||
        email.contains(search);

    final matchesYear = _selectedYear == 'All Years' ||
        year == _selectedYear;

    final matchesCourse = _selectedCourse == 'All Courses' ||
        course == _selectedCourse;

    final matchesSelectedStudent = _selectedStudentId == 'all' ||
        schedule['studentId'] == _selectedStudentId;

    return matchesSearch &&
        matchesYear &&
        matchesCourse &&
        matchesSelectedStudent;
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
              final name =
                  student['name'] as String? ?? 'Name not provided';
              final email =
                  student['email'] as String? ?? 'Unknown student';
              final year =
                  student['year'] as String? ?? 'Year not set';
              final course =
                  student['course'] as String? ?? 'Course not set';

              return SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(email),
                    Text(
                      '$year • $course',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
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

  Future<void> _deleteSchedule(
    Map<String, dynamic> schedule,
  ) async {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load schedules: ${snapshot.error}',
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final courseOptions = _getCourseOptions(data);

          if (!courseOptions.contains(_selectedCourse)) {
            _selectedCourse = 'All Courses';
          }

          final filteredSchedules = data.schedules
              .where(
                (schedule) =>
                    _matchesStudentFilters(schedule, data),
              )
              .toList();

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

          final selectedStudent = _selectedStudentId == 'all'
              ? null
              : data.students.cast<Map<String, dynamic>?>().firstWhere(
                    (student) =>
                        student?['id'] == _selectedStudentId,
                    orElse: () => null,
                  );

          final selectedStudentLabel =
              selectedStudent == null
                  ? 'All students'
                  : '${selectedStudent['name'] as String? ?? 'Name not provided'} '
                      '(${selectedStudent['email'] as String? ?? 'No email'})';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search student name or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedYear),
                        initialValue: _selectedYear,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Year Level',
                          border: OutlineInputBorder(),
                        ),
                        items: _yearOptions.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedYear = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedCourse),
                        initialValue: _selectedCourse,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                        ),
                        items: courseOptions.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(
                              course,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCourse = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedStudentId),
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
                      final name =
                          student['name'] as String? ??
                              'Name not provided';
                      final email =
                          student['email'] as String? ??
                              'Unknown student';

                      return DropdownMenuItem(
                        value: id,
                        child: Text(
                          '$name ($email)',
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
                const SizedBox(height: 8),
                Text(
                  'Selected: $selectedStudentLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  '${filteredSchedules.length} schedule(s) found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (filteredSchedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No schedules match your search or filters.',
                        textAlign: TextAlign.center,
                      ),
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

                    final student = _studentForSchedule(
                      schedule,
                      data,
                    );

                    final studentName =
                        student?['name'] as String? ??
                            'Name not provided';

                    final studentEmail = studentId == null
                        ? 'Unknown student'
                        : data.studentEmail(studentId);

                    final year =
                        student?['year'] as String? ??
                            'Year not set';

                    final course =
                        student?['course'] as String? ??
                            'Course not set';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          '${data.subjectCode(schedule)} '
                          '${data.subjectName(schedule)}',
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
                              Text('Student: $studentName'),
                              Text(studentEmail),
                              Text('$year • $course'),
                              const SizedBox(height: 4),
                              Text(_dayName(day)),
                              Text(
                                '${_formatTime(start)} - '
                                '${_formatTime(end)}',
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
