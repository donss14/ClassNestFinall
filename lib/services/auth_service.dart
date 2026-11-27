
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<AppUser?> register({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    required String year,
    required String course,
  }) async {
    final clean = email.trim().toLowerCase();

    if (role != UserRole.student) {
      throw StateError('Only student registration is allowed.');
    }

    final cleanName = name.trim();
    final cleanYear = year.trim();
    final cleanCourse = course.trim();

    if (cleanName.isEmpty ||
        cleanYear.isEmpty ||
        cleanCourse.isEmpty) {
      throw ArgumentError(
        'Please complete all student profile fields.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: clean,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw StateError('Firebase account creation failed.');
    }

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': clean,
        'role': 'student',
        'name': cleanName,
        'year': cleanYear,
        'course': cleanCourse,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await firebaseUser.delete();
      rethrow;
    }

    return AppUser(
      uid: firebaseUser.uid,
      email: clean,
      role: UserRole.student,
      name: cleanName,
      year: cleanYear,
      course: cleanCourse,
    );
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final clean = email.trim().toLowerCase();

    debugPrint('ADMIN DEBUG: Starting Firebase sign-in');

    final credential = await _auth.signInWithEmailAndPassword(
      email: clean,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      debugPrint('ADMIN DEBUG: Firebase user is null');
      return null;
    }

    debugPrint('ADMIN DEBUG: Firebase authentication successful');
    debugPrint('ADMIN DEBUG: Auth UID = ${firebaseUser.uid}');

    return _getAppUser(firebaseUser.uid);
  }

  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) return null;

    return _getAppUser(firebaseUser.uid);
  }

  Future<AppUser?> _getAppUser(String uid) async {
    debugPrint('ADMIN DEBUG: Checking admin collection');

    final adminDoc = await _firestore
        .collection('admin')
        .doc(uid)
        .get();

    debugPrint(
      'ADMIN DEBUG: Admin document exists = ${adminDoc.exists}',
    );

    if (adminDoc.exists) {
      final data = adminDoc.data()!;

      debugPrint('ADMIN DEBUG: Role = ${data['role']}');
      debugPrint(
        'ADMIN DEBUG: Email field is String = ${data['email'] is String}',
      );

      if (data['role'] != 'admin' || data['email'] is! String) {
        debugPrint('ADMIN DEBUG: Admin profile validation failed');
        return null;
      }

      debugPrint('ADMIN DEBUG: Admin profile accepted');

      return AppUser(
        uid: uid,
        email: data['email'] as String,
        role: UserRole.admin,
      );
    }

    debugPrint('ADMIN DEBUG: Checking student collection');

    final studentDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    debugPrint(
      'ADMIN DEBUG: Student document exists = ${studentDoc.exists}',
    );

    if (!studentDoc.exists) return null;

    final data = studentDoc.data()!;

    if (data['role'] != 'student' || data['email'] is! String) {
      return null;
    }

    return AppUser(
      uid: uid,
      email: data['email'] as String,
      role: UserRole.student,
      name: data['name'] as String?,
      year: data['year'] as String?,
      course: data['course'] as String?,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
