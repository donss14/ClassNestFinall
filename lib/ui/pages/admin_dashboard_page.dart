
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'students_management_page.dart';
import 'admin_subjects_management_page.dart';
import 'admin_schedules_management_page.dart';
import 'admin_room_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClassNest Admin'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Welcome, Admin!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage students, subjects, schedules, and rooms.',
          ),
          const SizedBox(height: 24),

          _DashboardCard(
            title: 'Students',
            subtitle: 'View registered student accounts',
            icon: Icons.people,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentsManagementPage(),
                ),
              );
            },
          ),

          _DashboardCard(
            title: 'Subjects',
            subtitle: 'Add, edit, and manage student subjects',
            icon: Icons.menu_book,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSubjectsManagementPage(),
                ),
              );
            },
          ),

          _DashboardCard(
            title: 'Schedules',
            subtitle: 'Manage class days, times, and rooms',
            icon: Icons.calendar_month,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSchedulesManagementPage(),
                ),
              );
            },
          ),

          _DashboardCard(
            title: 'Room Management',
            subtitle: 'View classroom assignments',
            icon: Icons.meeting_room,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminRoomManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 30),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}
