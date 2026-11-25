import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';

/// Horizontal Mon-Sun chips. [selectedDay] is 1 (Monday) to 7 (Sunday).
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onChanged,
  });

  final int selectedDay;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var day = 1; day <= 7; day++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(TimeUtils.dayShort[day - 1]),
                selected: selectedDay == day,
                onSelected: (_) => onChanged(day),
              ),
            ),
        ],
      ),
    );
  }
}
