import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';

/// Read-only field that opens a time picker when tapped.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.minutes,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(TimeUtils.formatMinutes(minutes)),
      ),
    );
  }
}
