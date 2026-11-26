
enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  final String uid;
  final String email;
  final UserRole role;

  String get roleLabel =>
      role == UserRole.admin ? 'Admin' : 'Student';
}
