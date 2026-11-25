
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app.dart';

import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/preferences_service.dart';

import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local database
  final database = DatabaseService.instance;

  // Initialize preferences
  final preferences = PreferencesService();

  runApp(
    MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(preferences),
        ),

        // Firebase Authentication Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            AuthService(),
          )..load(),
        ),

        // Schedule Provider
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(database)..load(),
        ),
      ],
      child: const ClassNestApp(),
    ),
  );
}
