/// ==========================================================================
/// settings_screen.dart — Settings & Profile Screen
/// ==========================================================================
/// User preferences and profile configuration.
/// Integrates the premium subscription upsell banner.
/// ==========================================================================

import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header ──
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(Icons.person, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Doe',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'alex.doe@example.com',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {},
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
              ),

              // ── Premium Subscription Banner (Upsell) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unlock AI predictions & advanced reports.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Show paywall string
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A11CB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Settings Sections ──
              _buildSettingsGroup(
                context,
                title: 'Preferences',
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Reminders',
                    trailing: const Text('9:00 PM', style: TextStyle(color: Colors.grey)),
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.dark_mode_outlined,
                    title: 'Theme',
                    trailing: const Text('System', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSettingsGroup(
                context,
                title: 'Data & Privacy',
                children: [
                  _buildListTile(context, icon: Icons.download_outlined, title: 'Export Data'),
                  _buildListTile(context, icon: Icons.lock_outline, title: 'Privacy Settings'),
                  _buildListTile(
                    context,
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Data',
                    color: Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSettingsGroup(
                context,
                title: 'Support',
                children: [
                  _buildListTile(context, icon: Icons.help_outline, title: 'Help Center'),
                  _buildListTile(context, icon: Icons.bug_report_outlined, title: 'Report a Bug'),
                ],
              ),
              const SizedBox(height: 32),

              // ── Sign Out ──
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: Sign out via AuthProvider
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'App Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
