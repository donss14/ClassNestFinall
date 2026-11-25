import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final user = context.watch<AuthProvider>().user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          Text('Account', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.email),
              subtitle: Text(user.roleLabel),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 32),
        ],
        Text('Appearance', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('System')),
            ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Light')),
            ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Dark')),
          ],
          selected: {themeProvider.themeMode},
          onSelectionChanged: (set) =>
              context.read<ThemeProvider>().setThemeMode(set.first),
        ),
        const SizedBox(height: 32),
        Text('About', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('ClassNest'),
            subtitle: Text(
                'Class schedules and room assignments for students of '
                "Divine Word College of Legazpi.\nGroup DPinili - CC105A"),
            isThreeLine: true,
          ),
        ),
      ],
    );
  }
}
