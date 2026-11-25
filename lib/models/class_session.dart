class ClassSession {
  const ClassSession({
    this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    required this.room,
    this.previousRoom,
    this.roomChangedAtMillis,
  });

  final int? id;
  final int subjectId;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String room;
  final String? previousRoom;
  final int? roomChangedAtMillis;

  bool get hasRoomChange =>
      previousRoom != null && roomChangedAtMillis != null;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'room': room,
      'previous_room': previousRoom,
      'room_changed_at': roomChangedAtMillis,
    };
  }

  factory ClassSession.fromMap(Map<String, Object?> map) {
    return ClassSession(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      dayOfWeek: map['day_of_week'] as int,
      startMinutes: map['start_minutes'] as int,
      endMinutes: map['end_minutes'] as int,
      room: map['room'] as String,
      previousRoom: map['previous_room'] as String?,
      roomChangedAtMillis: map['room_changed_at'] as int?,
    );
  }

  ClassSession copyWith({
    int? id,
    int? subjectId,
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    String? room,
    String? previousRoom,
    int? roomChangedAtMillis,
  }) {
    return ClassSession(
      id: id ?? this.id,
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