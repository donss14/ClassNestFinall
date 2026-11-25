import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';
import '../../models/class_session.dart';
import '../../models/room_status.dart';
import '../../models/subject.dart';

/// One room with its status: In use now or Free now, the current or next
/// class, and the latest room change.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.status,
    required this.subjectFor,
  });

  final RoomStatus status;
  final Subject? Function(ClassSession session) subjectFor;

  String _classText(ClassSession session) {
    final subject = subjectFor(session);
    final code = subject?.code ?? 'Class';
    return '$code, ${TimeUtils.formatRange(session.startMinutes, session.endMinutes)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = status.current;
    final next = status.next;
    final changed = status.changed;

    final String detail;
    if (current != null) {
      detail = 'Now: ${_classText(current)}';
    } else if (next != null) {
      detail = 'Next: ${_classText(next)}';
    } else {
      detail = 'No more classes today';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.meeting_room_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(status.room, style: theme.textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.inUse
                        ? scheme.errorContainer
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.inUse ? 'In use now' : 'Free now',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: status.inUse
                          ? scheme.onErrorContainer
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(detail, style: theme.textTheme.bodyMedium),
            if (changed != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: scheme.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${subjectFor(changed)?.code ?? 'Class'} moved here '
                        '(was ${changed.previousRoom})',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
