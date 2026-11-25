
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(PreferencesService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            AuthService(DatabaseService.instance),
            PreferencesService(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(DatabaseService.instance)..load(),
        ),
      ],
      child: const ClassNestApp(),
    ),
  );
}
