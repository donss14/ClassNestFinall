import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../organisms/sign_in_form.dart';
import '../templates/page_template.dart';

/// Sign in, or create an account, for students.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isRegister = false;
  bool _saving = false;

  Future<void> _submit(String email, String password, UserRole role) async {
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    final error = _isRegister
        ? await auth.register(email, password, role)
        : await auth.signIn(email, password);
    // On success the app switches to Home and this page is removed.
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: _isRegister ? 'Create account' : 'Sign in',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SignInForm(
          // A new key resets the fields when switching between the modes.
          key: ValueKey(_isRegister),
          isRegister: _isRegister,
          isSaving: _saving,
          onSubmit: _submit,
          onToggleMode: () => setState(() => _isRegister = !_isRegister),
        ),
      ),
    );
  }
}
