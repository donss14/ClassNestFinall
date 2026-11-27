
enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.year,
    this.course,
  });

  final String uid;
  final String email;
  final UserRole role;

  final String? name;
  final String? year;
  final String? course;

  String get roleLabel =>
      role == UserRole.admin ? 'Admin' : 'Student';
}
