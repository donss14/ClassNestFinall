import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../models/class_session.dart';
import '../models/subject.dart';
import '../ui/pages/auth_gate.dart';
import '../ui/pages/session_form_page.dart';
import '../ui/pages/subject_form_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.subjectForm:
        final arg = settings.arguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              SubjectFormPage(initial: arg is Subject ? arg : null),
        );
      case AppRoutes.sessionForm:
        final arg = settings.arguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              SessionFormPage(initial: arg is ClassSession ? arg : null),
        );
      case AppRoutes.home:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGate(),
        );
    }
  }
}
