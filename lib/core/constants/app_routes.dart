/// Central list of named routes. Never hard-code route strings elsewhere.
///
/// Schedule, Subjects, Rooms and Settings are tabs inside [home], so they are not
/// separate routes.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String subjectForm = '/subjects/form';
  static const String sessionForm = '/sessions/form';
}
