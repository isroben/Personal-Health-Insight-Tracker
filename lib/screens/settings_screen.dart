import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyCheckIn = true;
  bool _weeklyInsights = true;
  bool _medicationReminders = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        toolbarHeight: 100,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manage your account and preferences',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            _buildUserProfileCard(user, theme),
            const SizedBox(height: 24),

            // Profile Section
            _buildSectionHeader('Profile'),
            _buildCard([
              _buildSettingsTile(
                icon: Icons.person_outline,
                iconColor: Colors.blue,
                title: 'Edit Profile',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Icons.workspace_premium_outlined,
                iconColor: Colors.orange,
                title: 'Upgrade to Premium',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildCard([
              _buildSwitchTile(
                icon: Icons.notifications_none,
                title: 'Daily Check-in',
                value: _dailyCheckIn,
                onChanged: (v) => setState(() => _dailyCheckIn = v),
              ),
              const Divider(height: 1, indent: 56),
              _buildSwitchTile(
                icon: Icons.notifications_none,
                title: 'Weekly Insights',
                value: _weeklyInsights,
                onChanged: (v) => setState(() => _weeklyInsights = v),
              ),
              const Divider(height: 1, indent: 56),
              _buildSwitchTile(
                icon: Icons.notifications_none,
                title: 'Medication Reminders',
                value: _medicationReminders,
                onChanged: (v) => setState(() => _medicationReminders = v),
              ),
            ]),
            const SizedBox(height: 24),

            // Privacy & Data Section
            _buildSectionHeader('Privacy & Data'),
            _buildCard([
              _buildSettingsTile(
                icon: Icons.lock_outline,
                iconColor: Colors.blue,
                title: 'Privacy Settings',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Icons.file_download_outlined,
                iconColor: Colors.blue,
                title: 'Export Data',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildCard([
              _buildSettingsTile(
                icon: Icons.nightlight_outlined,
                iconColor: Colors.indigo,
                title: 'Dark Mode',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Icons.language_outlined,
                iconColor: Colors.blue,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader('Support'),
            _buildCard([
              _buildSettingsTile(
                icon: Icons.help_outline,
                iconColor: Colors.blue,
                title: 'Help & Support',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: 'Log Out',
                titleColor: Colors.red,
                onTap: () => _showSignOutDialog(context, ref),
              ),
            ]),
            const SizedBox(height: 48),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '© 2026 Health Tracker',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(UserModel user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF4C9EEB),
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color iconColor = const Color(0xFF4C9EEB),
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.black87,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF4C9EEB).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF4C9EEB), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4C9EEB),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Come back soon to continue your wellness journey.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
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
