import 'package:flutter/material.dart';

/// Shows the room, plus a highlighted note when the room was reassigned.
class RoomBadge extends StatelessWidget {
  const RoomBadge({super.key, required this.room, this.previousRoom});

  final String room;
  final String? previousRoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.meeting_room_outlined,
                  size: 16, color: scheme.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(room,
                  style: textTheme.labelLarge
                      ?.copyWith(color: scheme.onPrimaryContainer)),
            ],
          ),
        ),
        if (previousRoom != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz,
                    size: 16, color: scheme.onErrorContainer),
                const SizedBox(width: 4),
                Text('Room changed (was $previousRoom)',
                    style: textTheme.labelMedium
                        ?.copyWith(color: scheme.onErrorContainer)),
              ],
            ),
          ),
      ],
    );
  }
}
