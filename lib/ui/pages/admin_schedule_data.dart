
import '../../services/firestore_service.dart';

class AdminScheduleData {
  AdminScheduleData({
    required this.students,
    required this.schedules,
    required this.subjectsByStudent,
  });

  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> schedules;

  final Map<String, Map<String, Map<String, dynamic>>>
      subjectsByStudent;

  static Future<AdminScheduleData> load(
    FirestoreService firestore,
  ) async {
    final students = await firestore.getStudents();
    final schedules = await firestore.getAllSchedules();

    final subjectLists = await Future.wait(
      students.map((student) {
        return firestore.getSubjects(
          studentId: student['id'] as String,
        );
      }),
    );

    final subjectsByStudent =
        <String, Map<String, Map<String, dynamic>>>{};

    for (var i = 0; i < students.length; i++) {
      final studentId = students[i]['id'] as String;

      subjectsByStudent[studentId] = {
        for (final subject in subjectLists[i])
          if (subject['id'] is String)
            subject['id'] as String: subject,
      };
    }

    return AdminScheduleData(
      students: students,
      schedules: schedules,
      subjectsByStudent: subjectsByStudent,
    );
  }

  String studentEmail(String studentId) {
    final student = students.firstWhere(
      (item) => item['id'] == studentId,
      orElse: () => <String, dynamic>{},
    );

    return student['email'] as String? ?? 'Unknown student';
  }

  Map<String, dynamic>? subjectFor(
    Map<String, dynamic> schedule,
  ) {
    final studentId = schedule['studentId'] as String?;
    final subjectId = schedule['subjectId'] as String?;

    if (studentId == null || subjectId == null) return null;

    return subjectsByStudent[studentId]?[subjectId];
  }

  String subjectName(Map<String, dynamic> schedule) {
    return subjectFor(schedule)?['name'] as String? ??
        'Unknown subject';
  }

  String subjectCode(Map<String, dynamic> schedule) {
    return subjectFor(schedule)?['code'] as String? ?? '';
  }
}
