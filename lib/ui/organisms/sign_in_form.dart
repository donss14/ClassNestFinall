import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../models/app_user.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text_field.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.isRegister,
    required this.onSubmit,
    required this.onToggleMode,
    this.isSaving = false,
  });

  final bool isRegister;

  final void Function(
    String email,
    String password,
    UserRole role,
    String name,
    String year,
    String course,
  ) onSubmit;

  final VoidCallback onToggleMode;
  final bool isSaving;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _course = TextEditingController();

  static const UserRole _role = UserRole.student;

  static const List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  String? _selectedYear;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _course.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(
      _email.text.trim(),
      _password.text,
      _role,
      _name.text.trim(),
      _selectedYear ?? '',
      _course.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isRegister) ...[
            AppTextField(
              controller: _name,
              label: 'Full Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year Level',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
              ),
              items: _yearLevels.map((year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: widget.isSaving
                  ? null
                  : (value) {
                      setState(() => _selectedYear = value);
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your year level.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppTextField(
              controller: _course,
              label: 'Course',
              icon: Icons.menu_book_outlined,
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your course.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          AppTextField(
            controller: _email,
            label: 'Email',
            icon: Icons.email_outlined,
            validator: Validators.email,
            textCapitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: _password,
            label: 'Password',
            icon: Icons.lock_outline,
            validator: Validators.password,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            obscureText: true,
          ),
          const SizedBox(height: 28),

          AppButton(
            label: widget.isRegister ? 'Create account' : 'Sign in',
            icon: Icons.check,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),

          Center(
            child: TextButton(
              onPressed: widget.isSaving ? null : widget.onToggleMode,
              child: Text(
                widget.isRegister
                    ? 'Already have an account? Sign in'
                    : 'No account yet? Create one',
              ),
            ),
          ),
        ],
      ),
    );
  }
}