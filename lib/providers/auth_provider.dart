import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth);

  final AuthService _auth;

  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _auth.getCurrentUser();
    } catch (_) {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
  try {
    final user = await _auth.signIn(
      email: email,
      password: password,
    );

    if (user == null) {
      return 'Could not sign in.';
    }

    _user = user;
    notifyListeners();

    return null;
  } catch (e, stackTrace) {
    debugPrint('SIGN IN ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');

    return _errorMessage(e);
  }
}

  Future<String?> register(
  String email,
  String password,
  UserRole role,
) async {
  try {
    final user = await _auth.register(
      email: email,
      password: password,
      role: role,
    );

    if (user == null) {
      return 'Could not create account.';
    }

    _user = user;
    notifyListeners();

    return null;
  } catch (e, stackTrace) {
    debugPrint('REGISTRATION ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');

    return _errorMessage(e);
  }
}

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      _user = null;
      notifyListeners();
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Your password is too weak.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
