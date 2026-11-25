import 'package:flutter/material.dart';

import '../../core/constants/subject_colors.dart';
import '../atoms/color_dot.dart';

class SubjectColorPicker extends StatelessWidget {
  const SubjectColorPicker({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  final int selectedValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final value in subjectColorValues)
          Semantics(
            button: true,
            label: 'Choose color',
            selected: value == selectedValue,
            child: InkResponse(
              onTap: () => onChanged(value),
              radius: 24,
              child: ColorDot(
                color: Color(value),
                size: 36,
                selected: value == selectedValue,
              ),
            ),
          ),
      ],
    );
  }
}
