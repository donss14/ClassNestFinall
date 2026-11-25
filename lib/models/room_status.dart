import 'class_session.dart';

/// What is happening in one room right now.
class RoomStatus {
  const RoomStatus({
    required this.room,
    this.current,
    this.next,
    this.changed,
  });

  final String room;

  /// Class using the room at this moment, or null if the room is free.
  final ClassSession? current;

  /// Next class later today in this room.
  final ClassSession? next;

  /// Most recent class whose room was changed to this room.
  final ClassSession? changed;

  bool get inUse => current != null;
}
