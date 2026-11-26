
class ClassSession {
  const ClassSession({
    this.id,
    required this.studentId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    required this.room,
    this.previousRoom,
    this.roomChangedAtMillis,
  });

  // Firestore document ID
  final String? id;

  // Firebase Authentication UID of the student
  final String studentId;

  // Firestore document ID of the subject
  final String subjectId;

  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String room;
  final String? previousRoom;
  final int? roomChangedAtMillis;

  bool get hasRoomChange =>
      previousRoom != null && roomChangedAtMillis != null;

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'room': room,
      'previousRoom': previousRoom,
      'roomChangedAtMillis': roomChangedAtMillis,
    };
  }

  factory ClassSession.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    return ClassSession(
      id: id ?? map['id'] as String?,
      studentId: map['studentId'] as String,
      subjectId: map['subjectId'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      startMinutes: map['startMinutes'] as int,
      endMinutes: map['endMinutes'] as int,
      room: map['room'] as String,
      previousRoom: map['previousRoom'] as String?,
      roomChangedAtMillis: map['roomChangedAtMillis'] as int?,
    );
  }

  ClassSession copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    String? room,
    String? previousRoom,
    int? roomChangedAtMillis,
  }) {
    return ClassSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      room: room ?? this.room,
      previousRoom: previousRoom ?? this.previousRoom,
      roomChangedAtMillis:
          roomChangedAtMillis ?? this.roomChangedAtMillis,
    );
  }
}
