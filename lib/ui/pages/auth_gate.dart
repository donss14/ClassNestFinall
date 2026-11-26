
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_page.dart';
import 'home_page.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = auth.user;

    if (user == null) {
      return const SignInPage();
    }

    if (user.role == UserRole.admin) {
      return const AdminDashboardPage();
    }

    return const HomePage();
  }
}
