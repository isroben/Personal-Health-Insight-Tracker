/// ==========================================================================
/// settings_screen.dart — Settings & Profile Screen
/// ==========================================================================
/// User preferences and profile configuration.
/// Integrates the premium subscription upsell banner.
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/user_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final isPremium = user?.subscription == SubscriptionTier.premium;

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
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isPremium) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PREMIUM',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              user.email,
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
              if (!isPremium)
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
                            ref.read(subscriptionActionsProvider.notifier).upgradeToPremium();
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
                    ref.read(authActionsProvider.notifier).signOut();
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

