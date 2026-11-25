import 'package:flutter/material.dart';

import '../../models/app_user.dart';

/// Student / Admin choice used when creating an account.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment(
            value: UserRole.student,
            icon: Icon(Icons.school_outlined),
            label: Text('Student')),
        ButtonSegment(
            value: UserRole.admin,
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: Text('Admin')),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}
