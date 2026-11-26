
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/preferences_service.dart';

import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final preferences = PreferencesService();
  final firestoreService = FirestoreService(
    FirebaseFirestore.instance,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreService>.value(
          value: firestoreService,
        ),

        ChangeNotifierProvider(
          create: (_) => ThemeProvider(preferences),
        ),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            AuthService(),
          )..load(),
        ),

        ChangeNotifierProxyProvider<AuthProvider, ScheduleProvider>(
          create: (_) => ScheduleProvider(firestoreService),
          update: (_, auth, schedule) {
            schedule ??= ScheduleProvider(firestoreService);

            schedule.setStudentId(
              auth.isLoading ? null : auth.user?.uid,
            );

            return schedule;
          },
        ),
      ],
      child: const ClassNestApp(),
    ),
  );
}
