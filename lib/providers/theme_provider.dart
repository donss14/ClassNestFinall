import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Holds the current [ThemeMode] and saves it with [PreferencesService].
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs);

  final PreferencesService _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      _themeMode = await _prefs.loadThemeMode();
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _prefs.saveThemeMode(mode);
    } catch (_) {
      // Theme still applies for this session even if saving failed.
    }
  }
}
