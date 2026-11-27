
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import 'student_details_page.dart';

class StudentsManagementPage extends StatefulWidget {
  const StudentsManagementPage({super.key});

  @override
  State<StudentsManagementPage> createState() =>
      _StudentsManagementPageState();
}

class _StudentsManagementPageState
    extends State<StudentsManagementPage> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

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

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    _studentsFuture =
        context.read<FirestoreService>().getStudents();
  }

  Future<void> _refresh() async {
    setState(_loadStudents);
    await _studentsFuture;
  }

  List<Map<String, dynamic>> _filterStudents(
    List<Map<String, dynamic>> students,
  ) {
    final search = _searchController.text.trim().toLowerCase();

    return students.where((student) {
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

      final matchesCourse =
          _selectedCourse == 'All Courses' ||
          course == _selectedCourse;

      return matchesSearch && matchesYear && matchesCourse;
    }).toList();
  }

  List<String> _getCourseOptions(
    List<Map<String, dynamic>> students,
  ) {
    final courses = students
        .map((student) => student['course'] as String? ?? '')
        .where((course) => course.trim().isNotEmpty)
        .toSet()
        .toList();

    courses.sort();

    return ['All Courses', ...courses];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Students'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load students.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return const Center(
              child: Text('No registered students found.'),
            );
          }

          final courseOptions = _getCourseOptions(students);

          if (!courseOptions.contains(_selectedCourse)) {
            _selectedCourse = 'All Courses';
          }

          final filteredStudents = _filterStudents(students);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    8,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search name or email',
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
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filteredStudents.length} student(s) found',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredStudents.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 70),
                            Icon(
                              Icons.search_off,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No students match your search or filters.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            16,
                          ),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student =
                                filteredStudents[index];

                            final name =
                                student['name'] as String? ??
                                    'Name not provided';

                            final email =
                                student['email'] as String? ??
                                    'No email available';

                            final year =
                                student['year'] as String? ??
                                    'Year not set';

                            final course =
                                student['course'] as String? ??
                                    'Course not set';

                            final studentId =
                                student['id'] as String?;

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.all(12),
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(email),
                                      const SizedBox(height: 4),
                                      Text('$year • $course'),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: studentId == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                StudentDetailsPage(
                                              studentId: studentId,
                                              email: email,
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
        },
      ),
    );
  }
}
