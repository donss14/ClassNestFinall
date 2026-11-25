import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';

/// Who is signed in. Sign-in and register return an error message, or null
/// on success, like [ScheduleProvider].
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._prefs);

  final AuthService _auth;
  final PreferencesService _prefs;

  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;

  /// Restores the previous sign-in when the app starts.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final email = await _prefs.loadSignedInEmail();
      _user = email == null ? null : await _auth.findByEmail(email);
    } catch (_) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final user = await _auth.signIn(email: email, password: password);
      if (user == null) return 'Wrong email or password';
      await _start(user);
      return null;
    } catch (_) {
      return 'Could not sign in. Please try again.';
    }
  }

  Future<String?> register(
      String email, String password, UserRole role) async {
    try {
      final user =
          await _auth.register(email: email, password: password, role: role);
      if (user == null) return 'An account with this email already exists';
      await _start(user);
      return null;
    } catch (_) {
      return 'Could not create the account. Please try again.';
    }
  }

  Future<void> signOut() async {
    _user = null;
    notifyListeners();
    try {
      await _prefs.clearSignedInEmail();
    } catch (_) {
      // Signed out for this session even if clearing failed.
    }
  }

  Future<void> _start(AppUser user) async {
    _user = user;
    notifyListeners();
    try {
      await _prefs.saveSignedInEmail(user.email);
    } catch (_) {
      // Signed in for this session even if saving failed.
    }
  }
}
