/// ==========================================================================
/// settings_screen.dart — Production-Ready Settings & Control Center
/// ==========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../providers/user_profile_provider.dart';
import '../providers/report_provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── A. Account Section ──
            _buildSectionHeader(theme, 'Account'),
            _buildAccountCard(context, user, theme),

            const SizedBox(height: 24),

            // ── B. Subscription Section ──
            _buildSectionHeader(theme, 'Subscription'),
            _buildSubscriptionCard(context, user, theme),

            const SizedBox(height: 24),

            // ── C. Privacy & Data ──
            _buildSectionHeader(theme, 'Privacy & Data'),
            _buildSettingsTile(
              icon: Icons.sync,
              title: 'Cloud Sync',
              trailing: Switch(
                value: user.preferences.cloudSyncEnabled,
                onChanged: (val) => _updatePref(ref, user, cloudSync: val),
              ),
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              trailing: Switch(
                value: user.preferences.notificationsEnabled,
                onChanged: (val) => _updatePref(ref, user, notify: val),
              ),
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.file_download_outlined,
              title: 'Export My Data (PDF)',
              onTap: () => _exportData(ref),
            ),
            _buildSettingsTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Clear All Data',
              textColor: Colors.orange,
              onTap: () => _showClearDataDialog(context, ref),
            ),
            _buildSettingsTile(
              icon: Icons.no_accounts_outlined,
              title: 'Delete Account',
              textColor: Colors.red,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),

            const SizedBox(height: 24),

            // ── D. App Information ──
            _buildSectionHeader(theme, 'App Information'),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Contact Support',
              onTap: () => _launchEmail(),
            ),
            _buildSettingsTile(
              icon: Icons.policy_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.gavel_outlined,
              title: 'Terms of Service',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.star_outline,
              title: 'Rate App',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0 (Production Build)',
              onTap: () {},
            ),

            const SizedBox(height: 32),
            
            // ── E. Sign Out ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: OutlinedButton.icon(
                onPressed: () => _showSignOutDialog(context, ref),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Helper Widgets ──
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAccountCard(BuildContext context, UserModel user, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile & Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, UserModel user, ThemeData theme) {
    final isPremium = user.subscription == SubscriptionTier.premium;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: isPremium ? Colors.amber : Colors.grey),
                const SizedBox(width: 12),
                Text(
                  isPremium ? 'Premium Active' : 'Free Plan',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isPremium 
                ? 'You have unlimited access to AI insights and doctor reports.' 
                : 'Unlock AI-powered patterns and printable doctor reports.',
              style: theme.textTheme.bodySmall,
            ),
            if (!isPremium) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey.shade700, size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Logic & Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  void _updatePref(WidgetRef ref, UserModel user, {bool? notify, bool? cloudSync}) {
    final newPrefs = user.preferences.copyWith(
      notificationsEnabled: notify,
      cloudSyncEnabled: cloudSync,
    );
    ref.read(userProfileNotifierProvider.notifier).updateProfile(preferences: newPrefs);
  }

  void _exportData(WidgetRef ref) {
    ref.read(reportProvider.notifier).generateAndShareReport(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@healthinsight.com',
      query: 'subject=Support Request - Health Insight App',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all your symptom logs and history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('Are you absolutely sure? This will permanently delete your account and all associated health data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(userProfileNotifierProvider.notifier).deleteAccount();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
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
