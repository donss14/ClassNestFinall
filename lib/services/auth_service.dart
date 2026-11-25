
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

  // REGISTER NEW STUDENT
  Future<AppUser?> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final clean = email.trim().toLowerCase();

    // Prevent public registration as admin.
    if (role != UserRole.student) {
      throw StateError('Only student registration is allowed.');
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
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await firebaseUser.delete();
      rethrow;
    }

    return AppUser(
      email: clean,
      role: UserRole.student,
    );
  }

  // SIGN IN
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final clean = email.trim().toLowerCase();

    final credential = await _auth.signInWithEmailAndPassword(
      email: clean,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) return null;

    return _getAppUser(firebaseUser.uid);
  }

  // RESTORE CURRENT USER
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) return null;

    return _getAppUser(firebaseUser.uid);
  }

  // GET USER PROFILE FROM FIRESTORE
  
Future<AppUser?> _getAppUser(String uid) async {
  // First check the admin collection.
  final adminDoc = await _firestore
      .collection('admin')
      .doc(uid)
      .get();

  if (adminDoc.exists) {
    final data = adminDoc.data()!;

    return AppUser(
      email: (data['email'] as String)
          .replaceAll('"', '')
          .replaceAll("'", '')
          .trim()
          .toLowerCase(),
      role: UserRole.admin,
    );
  }

  // If not an admin, check the students collection.
  final userDoc = await _firestore
      .collection('users')
      .doc(uid)
      .get();

  if (!userDoc.exists) {
    throw StateError('User profile not found.');
  }

  final data = userDoc.data()!;

  final email = (data['email'] as String)
      .replaceAll('"', '')
      .replaceAll("'", '')
      .trim()
      .toLowerCase();

  final roleValue = (data['role'] as String)
      .replaceAll('"', '')
      .replaceAll("'", '')
      .trim()
      .toLowerCase();

  if (roleValue != 'student') {
    throw StateError('Invalid student role.');
  }

  return AppUser(
    email: email,
    role: UserRole.student,
  );
}

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
