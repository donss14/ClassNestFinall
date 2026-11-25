import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import 'database_service.dart';

/// Creates accounts and checks sign-ins against the local users table.
class AuthService {
  AuthService(this._db);

  final DatabaseService _db;

  String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  /// Returns null when the email is already used.
  Future<AppUser?> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final clean = email.trim().toLowerCase();
    if (await _db.getUserRow(clean) != null) return null;

    final salt = _newSalt();
    await _db.insertUser(
      email: clean,
      passwordHash: _hash(password, salt),
      salt: salt,
      role: role,
    );
    return AppUser(email: clean, role: role);
  }

  /// Returns null when the email or password is wrong.
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final row = await _db.getUserRow(email.trim().toLowerCase());
    if (row == null) return null;

    final salt = row['salt'] as String;
    if (_hash(password, salt) != row['password_hash']) return null;
    return _toUser(row);
  }

  Future<AppUser?> findByEmail(String email) async {
    final row = await _db.getUserRow(email);
    return row == null ? null : _toUser(row);
  }

  AppUser _toUser(Map<String, Object?> row) {
    return AppUser(
      email: row['email'] as String,
      role: UserRole.values.byName(row['role'] as String),
    );
  }
}
