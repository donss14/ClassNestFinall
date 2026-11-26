
import 'package:flutter/foundation.dart';

import '../core/utils/validators.dart';
import '../models/class_session.dart';
import '../models/room_status.dart';
import '../models/subject.dart';
import '../services/firestore_service.dart';

/// Manages the signed-in student's subjects and class schedule.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider(this._firestore);

  final FirestoreService _firestore;

  List<Subject> _subjects = [];
  List<ClassSession> _sessions = [];

  String? _studentId;
  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get studentId => _studentId;

  /// Called when the signed-in student changes.
  void setStudentId(String? uid) {
    if (_studentId == uid) return;

    _studentId = uid;
    _subjects = [];
    _sessions = [];
    _errorMessage = null;

    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    load();
  }

  Subject? subjectById(String id) {
    for (final subject in _subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  /// Sessions for [day] (1 = Monday ... 7 = Sunday).
  List<ClassSession> sessionsForDay(int day) =>
      _sessions.where((s) => s.dayOfWeek == day).toList();

  int sessionCountFor(String subjectId) =>
      _sessions.where((s) => s.subjectId == subjectId).length;

  /// Every room used in this student's schedule.
  List<RoomStatus> roomStatuses(DateTime now) {
    final day = now.weekday;
    final minutes = now.hour * 60 + now.minute;

    final byRoom = <String, List<ClassSession>>{};

    for (final session in _sessions) {
      byRoom
          .putIfAbsent(session.room.trim().toLowerCase(), () => [])
          .add(session);
    }

    final statuses = <RoomStatus>[];

    for (final sessions in byRoom.values) {
      ClassSession? current;
      ClassSession? next;
      ClassSession? changed;

      for (final session in sessions) {
        if (session.dayOfWeek == day) {
          if (session.startMinutes <= minutes &&
              minutes < session.endMinutes) {
            current = session;
          } else if (session.startMinutes > minutes &&
              (next == null ||
                  session.startMinutes < next.startMinutes)) {
            next = session;
          }
        }

        if (session.hasRoomChange &&
            (changed == null ||
                session.roomChangedAtMillis! >
                    changed.roomChangedAtMillis!)) {
          changed = session;
        }
      }

      statuses.add(
        RoomStatus(
          room: sessions.first.room.trim(),
          current: current,
          next: next,
          changed: changed,
        ),
      );
    }

    statuses.sort(
      (a, b) => a.room.toLowerCase().compareTo(b.room.toLowerCase()),
    );

    return statuses;
  }

  Future<void> load() async {
    final uid = _studentId;

    if (uid == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final subjectMaps = await _firestore.getSubjects(studentId: uid);
      final scheduleMaps = await _firestore.getSchedules(studentId: uid);

      // Ignore results if the signed-in account changed during loading.
      if (_studentId != uid) return;

      _subjects = subjectMaps
          .map((map) => Subject.fromMap(map, id: map['id'] as String))
          .toList();

      _sessions = scheduleMaps
          .map((map) => ClassSession.fromMap(map, id: map['id'] as String))
          .toList();
    } catch (_) {
      if (_studentId == uid) {
        _errorMessage =
            'Could not load your schedule. Please try again.';
      }
    } finally {
      if (_studentId == uid) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<String?> saveSubject(Subject subject) async {
    final uid = _studentId;
    if (uid == null) return 'Please sign in first';

    final code = subject.code.trim();

    final duplicate = _subjects.any(
      (s) =>
          s.id != subject.id &&
          s.code.trim().toLowerCase() == code.toLowerCase(),
    );

    if (duplicate) {
      return 'A subject with this code already exists';
    }

    final clean = subject.copyWith(
      code: code,
      name: subject.name.trim(),
    );

    try {
      await _firestore.saveSubject(
        id: clean.id,
        data: {
          ...clean.toMap(),
          'studentId': uid,
        },
      );

      await load();
      return null;
    } catch (_) {
      return 'Could not save the subject. Please try again.';
    }
  }

  Future<String?> deleteSubject(String id) async {
    final uid = _studentId;
    if (uid == null) return 'Please sign in first';

    try {
      // Remove this subject's schedules first because Firestore
      // does not automatically delete related documents.
      final schedules = await _firestore.getSchedules(studentId: uid);

      for (final schedule in schedules) {
        if (schedule['subjectId'] == id) {
          await _firestore.deleteSchedule(schedule['id'] as String);
        }
      }

      await _firestore.deleteSubject(id);
      await load();
      return null;
    } catch (_) {
      return 'Could not delete the subject. Please try again.';
    }
  }

  Future<String?> saveSession(ClassSession session) async {
    final uid = _studentId;
    if (uid == null) return 'Please sign in first';

    if (session.studentId != uid) {
      return 'This class does not belong to the signed-in student';
    }

    final rangeError =
        Validators.timeRange(session.startMinutes, session.endMinutes);

    if (rangeError != null) return rangeError;

    try {
      final conflict = await _firestore.hasScheduleConflict(
        studentId: uid,
        dayOfWeek: session.dayOfWeek,
        startMinutes: session.startMinutes,
        endMinutes: session.endMinutes,
        excludeScheduleId: session.id,
      );

      if (conflict) {
        return 'This time overlaps another class on that day';
      }

      final clean = session.copyWith(room: session.room.trim());

      await _firestore.saveSchedule(
        id: clean.id,
        data: clean.toMap(),
      );

      await load();
      return null;
    } catch (_) {
      return 'Could not save the class. Please try again.';
    }
  }

  Future<String?> deleteSession(String id) async {
    try {
      await _firestore.deleteSchedule(id);
      await load();
      return null;
    } catch (_) {
      return 'Could not delete the class. Please try again.';
    }
  }

  Future<String?> dismissRoomChange(String id) async {
    try {
      final session = _sessions.firstWhere((s) => s.id == id);

      // Create a fresh session without the room-change information.
      final updated = ClassSession(
        id: session.id,
        studentId: session.studentId,
        subjectId: session.subjectId,
        dayOfWeek: session.dayOfWeek,
        startMinutes: session.startMinutes,
        endMinutes: session.endMinutes,
        room: session.room,
        previousRoom: null,
        roomChangedAtMillis: null,
      );

      await _firestore.saveSchedule(
        id: id,
        data: updated.toMap(),
      );

      await load();
      return null;
    } catch (_) {
      return 'Could not update the class. Please try again.';
    }
  }
}
