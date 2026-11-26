
import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../templates/page_template.dart';
import 'schedule_page.dart';
import 'subjects_page.dart';
import 'rooms_page.dart';
import 'settings_page.dart';

/// Hosts four tabs: Schedule, Subjects, Rooms and Settings.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = [
    'My Schedule',
    'Subjects',
    'Room Tracker',
    'Settings',
  ];

  Widget? _buildFab() {
    switch (_index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.sessionForm),
          icon: const Icon(Icons.add),
          label: const Text('Add class'),
        );

      case 1:
        return FloatingActionButton.extended(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.subjectForm),
          icon: const Icon(Icons.add),
          label: const Text('Add subject'),
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: _titles[_index],

      body: IndexedStack(
        index: _index,
        children: const [
          SchedulePage(),
          SubjectsPage(),
          RoomsPage(),
          SettingsPage(),
        ],
      ),

      floatingActionButton: _buildFab(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
