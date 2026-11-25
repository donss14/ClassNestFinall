import 'package:flutter/foundation.dart';

import '../core/utils/validators.dart';
import '../models/class_session.dart';
import '../models/room_status.dart';
import '../models/subject.dart';
import '../services/database_service.dart';

/// State for subjects and class sessions.
///
/// Save/delete methods return an error message, or null on success, so pages
/// can show feedback without knowing about the database.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider(this._db);

  final DatabaseService _db;

  List<Subject> _subjects = [];
  List<ClassSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Subject? subjectById(int id) {
    for (final subject in _subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  /// Sessions for [day] (1 = Monday ... 7 = Sunday), earliest first.
  List<ClassSession> sessionsForDay(int day) =>
      _sessions.where((s) => s.dayOfWeek == day).toList();

  int sessionCountFor(int subjectId) =>
      _sessions.where((s) => s.subjectId == subjectId).length;

  /// Every room used in the schedule, with its status at [now].
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
          if (session.startMinutes <= minutes && minutes < session.endMinutes) {
            current = session;
          } else if (session.startMinutes > minutes &&
              (next == null || session.startMinutes < next.startMinutes)) {
            next = session;
          }
        }
        if (session.hasRoomChange &&
            (changed == null ||
                session.roomChangedAtMillis! > changed.roomChangedAtMillis!)) {
          changed = session;
        }
      }

      statuses.add(RoomStatus(
        room: sessions.first.room.trim(),
        current: current,
        next: next,
        changed: changed,
      ));
    }

    statuses.sort(
        (a, b) => a.room.toLowerCase().compareTo(b.room.toLowerCase()));
    return statuses;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _refresh();
    } catch (_) {
      _errorMessage = 'Could not load your schedule. Please restart the app.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refresh() async {
    _subjects = await _db.getSubjects();
    _sessions = await _db.getSessions();
  }

  Future<String?> saveSubject(Subject subject) async {
    final code = subject.code.trim();
    final duplicate = _subjects.any((s) =>
        s.id != subject.id && s.code.trim().toLowerCase() == code.toLowerCase());
    if (duplicate) return 'A subject with this code already exists';

    final clean = subject.copyWith(code: code, name: subject.name.trim());
    try {
      if (clean.id == null) {
        await _db.insertSubject(clean);
      } else {
        await _db.updateSubject(clean);
      }
      await _refresh();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not save the subject. Please try again.';
    }
  }

  Future<String?> deleteSubject(int id) async {
    try {
      await _db.deleteSubject(id);
      await _refresh();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not delete the subject. Please try again.';
    }
  }

  Future<String?> saveSession(ClassSession session) async {
    final rangeError =
        Validators.timeRange(session.startMinutes, session.endMinutes);
    if (rangeError != null) return rangeError;

    try {
      final conflict = await _db.hasConflict(
        dayOfWeek: session.dayOfWeek,
        startMinutes: session.startMinutes,
        endMinutes: session.endMinutes,
        excludeSessionId: session.id,
      );
      if (conflict) return 'This time overlaps another class on that day';

      final clean = session.copyWith(room: session.room.trim());
      if (clean.id == null) {
        await _db.insertSession(clean);
      } else {
        await _db.updateSession(clean);
      }
      await _refresh();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not save the class. Please try again.';
    }
  }

  Future<String?> deleteSession(int id) async {
    try {
      await _db.deleteSession(id);
      await _refresh();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not delete the class. Please try again.';
    }
  }

  Future<String?> dismissRoomChange(int sessionId) async {
    try {
      await _db.dismissRoomChange(sessionId);
      await _refresh();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not update the class. Please try again.';
    }
  }
}
