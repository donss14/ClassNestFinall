import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';
import '../../models/class_session.dart';
import '../../models/subject.dart';
import '../molecules/room_badge.dart';

class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.subject,
    required this.session,
    required this.onEdit,
    required this.onDelete,
    required this.onDismissChange,
  });

  final Subject subject;
  final ClassSession session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismissChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instructor = subject.instructor;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: Color(subject.colorValue)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            TimeUtils.formatRange(
                                session.startMinutes, session.endMinutes),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'More options',
                          onSelected: (value) =>
                              value == 'edit' ? onEdit() : onDelete(),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${subject.code} - ${subject.name}',
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (instructor != null && instructor.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          instructor,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    const SizedBox(height: 8),
                    RoomBadge(
                      room: session.room,
                      previousRoom: session.previousRoom,
                    ),
                    if (session.hasRoomChange)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onDismissChange,
                          child: const Text('Got it'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
