/// ==========================================================================
/// settings_screen.dart — User Profile & App Preferences
/// ==========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ── Profile Section ──
            if (user != null)
              _buildProfileHeader(user, theme)
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 32),
            
            _buildSectionHeader(theme, 'Subscription'),
            _buildSettingsTile(
              icon: Icons.workspace_premium,
              title: 'Membership Tier',
              subtitle: user?.subscription.name.toUpperCase() ?? 'FREE',
              onTap: () {},
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(theme, 'Account & Privacy'),
            _buildSettingsTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Data & Privacy',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Export My Data',
              onTap: () {},
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(theme, 'App Information'),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About App',
              subtitle: 'v1.0.0',
              onTap: () {},
            ),

            const SizedBox(height: 40),
            
            // ── Sign Out Button ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showSignOutDialog(context, ref);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: user.profilePhotoUrl != null
              ? Image.network(user.profilePhotoUrl!)
              : Icon(Icons.person, size: 32, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your data will remain synced with the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authActionsProvider.notifier).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
