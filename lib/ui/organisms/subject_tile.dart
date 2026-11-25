import 'package:flutter/material.dart';

import '../../models/subject.dart';
import '../atoms/color_dot.dart';

class SubjectTile extends StatelessWidget {
  const SubjectTile({
    super.key,
    required this.subject,
    required this.classCount,
    required this.onTap,
    required this.onDelete,
  });

  final Subject subject;
  final int classCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final instructor = subject.instructor;
    final details = [
      '$classCount ${classCount == 1 ? 'class' : 'classes'} per week',
      if (instructor != null && instructor.isNotEmpty) instructor,
    ].join(' | ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: ColorDot(color: Color(subject.colorValue), size: 20),
        title: Text('${subject.code} - ${subject.name}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(details),
        trailing: IconButton(
          tooltip: 'Delete subject',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
