import 'package:flutter/material.dart';

import '../../models/subject.dart';
import '../atoms/color_dot.dart';

/// Choose one subject from chips; shows [errorText] when nothing is chosen.
class SubjectPicker extends StatelessWidget {
  const SubjectPicker({
    super.key,
    required this.subjects,
    required this.selectedId,
    required this.onChanged,
    this.errorText,
  });

  final List<Subject> subjects;
  final int? selectedId;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final subject in subjects)
              ChoiceChip(
                avatar: ColorDot(color: Color(subject.colorValue)),
                label: Text(subject.code),
                selected: subject.id == selectedId,
                onSelected: (_) => onChanged(subject.id!),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errorText!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ),
      ],
    );
  }
}
