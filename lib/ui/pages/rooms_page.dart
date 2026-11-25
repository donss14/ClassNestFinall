import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/schedule_provider.dart';
import '../molecules/empty_state.dart';
import '../organisms/room_card.dart';

/// Room Tracker: every room used in the schedule and whether it is in use.
class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Re-check once a minute so In use / Free stays correct.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rooms = provider.roomStatuses(DateTime.now());
    if (rooms.isEmpty) {
      return const EmptyState(
        icon: Icons.meeting_room_outlined,
        title: 'No rooms yet',
        message: 'Rooms appear here once you add classes in the Schedule tab.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: rooms.length,
      itemBuilder: (context, i) => RoomCard(
        status: rooms[i],
        subjectFor: (session) => provider.subjectById(session.subjectId),
      ),
    );
  }
}
