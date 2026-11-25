import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeKey = 'theme_mode';
  static const String _signedInKey = 'signed_in_email';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<ThemeMode> loadThemeMode() async {
    final savedMode = await _preferences.getString(_themeKey);

    switch (savedMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _preferences.setString(_themeKey, mode.name);
  }

  Future<String?> loadSignedInEmail() => _preferences.getString(_signedInKey);

  Future<void> saveSignedInEmail(String email) async {
    await _preferences.setString(_signedInKey, email);
  }

  Future<void> clearSignedInEmail() async {
    await _preferences.remove(_signedInKey);
  }
}
