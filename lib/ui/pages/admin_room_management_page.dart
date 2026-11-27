
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

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedYear = 'All Years';
  String _selectedCourse = 'All Courses';

  final List<String> _yearOptions = [
    'All Years',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  FirestoreService get _firestore =>
      context.read<FirestoreService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final matchesYear =
        _selectedYear == 'All Years' || year == _selectedYear;

    final matchesCourse =
        _selectedCourse == 'All Courses' ||
            course == _selectedCourse;

    return matchesSearch && matchesYear && matchesCourse;
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
                      'Could not load room assignments: ${snapshot.error}',
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

          final rooms =
              <String, List<Map<String, dynamic>>>{};

          for (final schedule in filteredSchedules) {
            final room =
                (schedule['room'] as String? ?? '').trim();

            final roomName =
                room.isEmpty ? 'No room assigned' : room;

            rooms.putIfAbsent(roomName, () => []).add(schedule);
          }

          final roomNames = rooms.keys.toList()
            ..sort(
              (a, b) => a.toLowerCase().compareTo(
                    b.toLowerCase(),
                  ),
            );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 16),
                Text(
                  '${roomNames.length} room group(s) • '
                  '${filteredSchedules.length} scheduled class(es)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (roomNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text(
                        'No room assignments match your search or filters.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ...roomNames.map((roomName) {
                  final roomSchedules = rooms[roomName]!;

                  roomSchedules.sort((a, b) {
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

                        final student =
                            _studentForSchedule(schedule, data);

                        final studentName =
                            student?['name'] as String? ??
                                'Name not provided';

                        final email =
                            data.studentEmail(studentId);

                        final year =
                            student?['year'] as String? ??
                                'Year not set';

                        final course =
                            student?['course'] as String? ??
                                'Course not set';

                        final start =
                            _formatTime(schedule['startMinutes']);

                        final end =
                            _formatTime(schedule['endMinutes']);

                        return ListTile(
                          title: Text(
                            data.subjectName(schedule),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Student: $studentName'),
                                Text(email),
                                Text('$year • $course'),
                                const SizedBox(height: 4),
                                Text(_dayName(schedule['dayOfWeek'])),
                                Text('$start - $end'),
                              ],
                            ),
                          ),
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
