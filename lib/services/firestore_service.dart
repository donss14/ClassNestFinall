
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  // Get all students (for future admin dashboard).
  Future<List<Map<String, dynamic>>> getStudents() async {
    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // Get subjects belonging to one student.
  Future<List<Map<String, dynamic>>> getSubjects({
    required String studentId,
  }) async {
    final snapshot = await _firestore
        .collection('subjects')
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // Add or update a subject.
  Future<String> saveSubject({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    final collection = _firestore.collection('subjects');

    if (id == null) {
      final doc = await collection.add(data);
      return doc.id;
    }

    await collection.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  // Delete a subject.
  Future<void> deleteSubject(String id) async {
    await _firestore.collection('subjects').doc(id).delete();
  }

  // Get schedules belonging to one student.
  Future<List<Map<String, dynamic>>> getSchedules({
    required String studentId,
  }) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // Get all schedules (for future admin features).
  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    final snapshot = await _firestore.collection('schedules').get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // Add or update a schedule.
  Future<String> saveSchedule({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    final collection = _firestore.collection('schedules');

    if (id == null) {
      final doc = await collection.add(data);
      return doc.id;
    }

    await collection.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  // Delete a schedule.
  Future<void> deleteSchedule(String id) async {
    await _firestore.collection('schedules').doc(id).delete();
  }

  // Check for overlapping schedules for the same student and day.
  Future<bool> hasScheduleConflict({
    required String studentId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    String? excludeScheduleId,
  }) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('studentId', isEqualTo: studentId)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == excludeScheduleId) continue;

      final data = doc.data();

      if (data['dayOfWeek'] != dayOfWeek) continue;

      final existingStart = data['startMinutes'] as int;
      final existingEnd = data['endMinutes'] as int;

      if (startMinutes < existingEnd && endMinutes > existingStart) {
        return true;
      }
    }

    return false;
  }
}
