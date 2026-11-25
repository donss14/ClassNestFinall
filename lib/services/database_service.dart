import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/class_session.dart';
import '../models/subject.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const int _databaseVersion = 2;
  static const String _databaseName = 'classnav.db';

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);

    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subjects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL COLLATE NOCASE UNIQUE,
            name TEXT NOT NULL,
            instructor TEXT,
            color_value INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE class_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            day_of_week INTEGER NOT NULL,
            start_minutes INTEGER NOT NULL,
            end_minutes INTEGER NOT NULL,
            room TEXT NOT NULL,
            previous_room TEXT,
            room_changed_at INTEGER,
            FOREIGN KEY (subject_id)
              REFERENCES subjects(id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE INDEX sessions_day_time
          ON class_sessions(day_of_week, start_minutes)
        ''');

        await _createUsersTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createUsersTable(db);
      },
    );

    return _database!;
  }

  static Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
  }

  // SUBJECTS

  Future<List<Subject>> getSubjects() async {
    final db = await _db;
    final rows = await db.query(
      'subjects',
      orderBy: 'code COLLATE NOCASE ASC',
    );

    return rows.map((row) => Subject.fromMap(row)).toList();
  }

  Future<int> insertSubject(Subject subject) async {
    final db = await _db;
    final data = subject.toMap()..remove('id');

    return db.insert('subjects', data);
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await _db;

    return db.update(
      'subjects',
      subject.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await _db;

    return db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CLASS SESSIONS

  Future<List<ClassSession>> getSessions() async {
    final db = await _db;
    final rows = await db.query(
      'class_sessions',
      orderBy: 'day_of_week ASC, start_minutes ASC',
    );

    return rows.map((row) => ClassSession.fromMap(row)).toList();
  }

  Future<int> insertSession(ClassSession session) async {
    final db = await _db;
    final data = session.toMap()..remove('id');

    return db.insert('class_sessions', data);
  }

  Future<int> updateSession(ClassSession session) async {
    final db = await _db;

    return db.transaction((txn) async {
      final existingRows = await txn.query(
        'class_sessions',
        where: 'id = ?',
        whereArgs: [session.id],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        throw StateError('Class session not found');
      }

      final existing = ClassSession.fromMap(existingRows.first);

      final roomChanged = existing.room.trim() != session.room.trim();

      final updated = session.copyWith(
        previousRoom: roomChanged
            ? existing.room
            : existing.previousRoom,
        roomChangedAtMillis: roomChanged
            ? DateTime.now().millisecondsSinceEpoch
            : existing.roomChangedAtMillis,
      );

      return txn.update(
        'class_sessions',
        updated.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [session.id],
      );
    });
  }

  Future<int> deleteSession(int id) async {
    final db = await _db;

    return db.delete(
      'class_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasConflict({
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    int? excludeSessionId,
  }) async {
    final db = await _db;

    final conditions = <String>[
      'day_of_week = ?',
      'start_minutes < ?',
      'end_minutes > ?',
    ];

    final arguments = <Object?>[
      dayOfWeek,
      endMinutes,
      startMinutes,
    ];

    if (excludeSessionId != null) {
      conditions.add('id != ?');
      arguments.add(excludeSessionId);
    }

    final rows = await db.query(
      'class_sessions',
      columns: ['id'],
      where: conditions.join(' AND '),
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<int> dismissRoomChange(int sessionId) async {
    final db = await _db;

    return db.update(
      'class_sessions',
      {
        'previous_room': null,
        'room_changed_at': null,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // USERS

  Future<Map<String, Object?>?> getUserRow(String email) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertUser({
    required String email,
    required String passwordHash,
    required String salt,
    required UserRole role,
  }) async {
    final db = await _db;

    return db.insert('users', {
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role.name,
    });
  }
}
