import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/app_preferences_provider.dart';
import '../models/user_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SharedPreferences? _prefs;

  // Local state for UI toggles and preferences
  bool _syncGoogleFit = false;
  bool _shareData = false;
  
  bool _symptomReminders = true;
  bool _medicationReminders = false;
  bool _hydrationReminders = true;

  bool _biometricLogin = false;
  String _autoLockTimeout = '5 Minutes';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncGoogleFit = _prefs?.getBool('syncGoogleFit') ?? false;
      _shareData = _prefs?.getBool('shareData') ?? false;
      
      _symptomReminders = _prefs?.getBool('symptomReminders') ?? true;
      _medicationReminders = _prefs?.getBool('medicationReminders') ?? false;
      _hydrationReminders = _prefs?.getBool('hydrationReminders') ?? true;

      _biometricLogin = _prefs?.getBool('biometricLogin') ?? false;
      _autoLockTimeout = _prefs?.getString('autoLockTimeout') ?? '5 Minutes';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    if (_prefs == null) return;
    if (value is bool) await _prefs!.setBool(key, value);
    if (value is String) await _prefs!.setString(key, value);
    if (value is double) await _prefs!.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final appPrefs = ref.watch(appPreferencesProvider);

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
        toolbarHeight: 60,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile & Account
            _UserProfileSection(user: user),
            const SizedBox(height: 32),

            // 2. Health Data & Privacy
            _SectionHeader(title: 'Health Data & Privacy'),
            _SectionCard(children: [
              _SettingsSwitch(
                icon: Icons.health_and_safety_outlined,
                iconColor: Colors.redAccent,
                title: 'Sync with Google Fit / Apple Health',
                value: _syncGoogleFit,
                onChanged: (v) {
                  setState(() => _syncGoogleFit = v);
                  _savePreference('syncGoogleFit', v);
                },
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.file_download_outlined,
                iconColor: Colors.blue,
                title: 'Export Data (CSV / PDF)',
                onTap: () => _showExportDialog(context),
              ),
              const _Divider(),
              _SettingsSwitch(
                icon: Icons.share_outlined,
                iconColor: Colors.green,
                title: 'Enable Data Sharing',
                subtitle: 'Share anonymized insights for research',
                value: _shareData,
                onChanged: (v) {
                  setState(() => _shareData = v);
                  _savePreference('shareData', v);
                },
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.blueGrey,
                title: 'Privacy Options',
                onTap: () {},
              )
            ]),
            const SizedBox(height: 32),

            // 3. Notifications & Reminders
            _SectionHeader(title: 'Notifications & Reminders'),
            _SectionCard(children: [
              _SettingsSwitch(
                icon: Icons.notifications_active_outlined,
                iconColor: Colors.orange,
                title: 'Symptom Reminders',
                value: _symptomReminders,
                onChanged: (v) {
                  setState(() => _symptomReminders = v);
                  _savePreference('symptomReminders', v);
                },
              ),
              const _Divider(),
              _SettingsSwitch(
                icon: Icons.medication_outlined,
                iconColor: Colors.pink,
                title: 'Medication Reminders',
                value: _medicationReminders,
                onChanged: (v) {
                  setState(() => _medicationReminders = v);
                  _savePreference('medicationReminders', v);
                },
              ),
              const _Divider(),
              _SettingsSwitch(
                icon: Icons.water_drop_outlined,
                iconColor: Colors.lightBlue,
                title: 'Hydration Reminders',
                value: _hydrationReminders,
                onChanged: (v) {
                  setState(() => _hydrationReminders = v);
                  _savePreference('hydrationReminders', v);
                },
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.schedule_outlined,
                iconColor: Colors.purple,
                title: 'Customize Time/Frequency',
                onTap: () {},
              )
            ]),
            const SizedBox(height: 32),

            // 4. App Preferences
            _SectionHeader(title: 'App Preferences'),
            _SectionCard(children: [
              _SettingsDropdown(
                icon: Icons.palette_outlined,
                iconColor: Colors.teal,
                title: 'Theme',
                value: appPrefs.themeModeStr,
                items: const ['Light', 'Dark', 'System'],
                onChanged: (v) {
                  ref.read(appPreferencesProvider.notifier).setThemeMode(v!);
                },
              ),
              const _Divider(),
              _SettingsDropdown(
                icon: Icons.square_foot_outlined,
                iconColor: Colors.amber,
                title: 'Units',
                value: user.preferences.unit == MeasurementUnit.metric ? 'Metric' : 'Imperial',
                items: const ['Metric', 'Imperial'],
                onChanged: (v) {
                  final newUnit = v == 'Metric' ? MeasurementUnit.metric : MeasurementUnit.imperial;
                  final updatedPrefs = user.preferences.copyWith(unit: newUnit).toMap();
                  ref.read(userProfileNotifierProvider.notifier).updateProfile(preferences: updatedPrefs);
                },
              ),
              const _Divider(),
              _SettingsDropdown(
                icon: Icons.language_outlined,
                iconColor: Colors.blue,
                title: 'Language',
                value: appPrefs.localeStr,
                items: const ['English', 'Spanish', 'French', 'German'],
                onChanged: (v) {
                  ref.read(appPreferencesProvider.notifier).setLanguage(v!);
                },
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.text_fields_outlined,
                iconColor: Colors.indigo,
                title: 'Font Size',
                trailing: Text('${(appPrefs.textScaleFactor * 100).toInt()}%', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                onTap: () => _showFontSizeDialog(context, ref, appPrefs.textScaleFactor),
              )
            ]),
            const SizedBox(height: 32),

            // 5. Security
            _SectionHeader(title: 'Security'),
            _SectionCard(children: [
              _SettingsSwitch(
                icon: Icons.fingerprint,
                iconColor: Colors.blueGrey,
                title: 'Biometric Login (Face ID/Touch ID)',
                value: _biometricLogin,
                onChanged: (v) {
                  setState(() => _biometricLogin = v);
                  _savePreference('biometricLogin', v);
                },
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.pin_outlined,
                iconColor: Colors.deepPurple,
                title: 'Setup Passcode/PIN',
                onTap: () {},
              ),
              const _Divider(),
              _SettingsDropdown(
                icon: Icons.timer_outlined,
                iconColor: Colors.brown,
                title: 'Auto-Lock Timeout',
                value: _autoLockTimeout,
                items: const ['Immediate', '1 Minute', '5 Minutes', 'Never'],
                onChanged: (v) {
                  setState(() => _autoLockTimeout = v!);
                  _savePreference('autoLockTimeout', v);
                },
              ),
            ]),
            const SizedBox(height: 32),

            // 6. Integrations & Devices
            _SectionHeader(title: 'Integrations & Devices'),
            _SectionCard(children: [
              _SettingsTile(
                icon: Icons.watch_outlined,
                iconColor: Colors.black87,
                title: 'Connect Wearable Devices',
                subtitle: 'Apple Watch, Fitbit, Garmin',
                onTap: () {},
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.api_outlined,
                iconColor: Colors.blueAccent,
                title: 'Third-party Health Apps',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),

            // 7. Support & Feedback
            _SectionHeader(title: 'Support & Feedback'),
            _SectionCard(children: [
              _SettingsTile(
                icon: Icons.help_outline,
                iconColor: Colors.green,
                title: 'Help & FAQ',
                onTap: () {},
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.contact_support_outlined,
                iconColor: Colors.orange,
                title: 'Contact Support',
                onTap: () {},
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.bug_report_outlined,
                iconColor: Colors.red,
                title: 'Report a Bug',
                onTap: () {},
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                iconColor: Colors.purple,
                title: 'Send Feedback',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),

            // 8. About
            _SectionHeader(title: 'About'),
            _SectionCard(children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: Colors.blue,
                title: 'App Version',
                trailing: const Text('1.0.0 (Build 42)', style: TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Privacy Policy',
                onTap: () {},
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.policy_outlined,
                title: 'Licenses & Credits',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 48),

            // Footer Log Out Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showSignOutDialog(context, ref),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose the format you want to export your health data to.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CSV')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('PDF')),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref, double currentSize) {
    double fontSize = currentSize;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Adjust Font Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${(fontSize * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C9EEB))),
                    const Text('A', style: TextStyle(fontSize: 22, color: Colors.grey)),
                  ],
                ),
                Slider(
                  value: fontSize,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  activeColor: const Color(0xFF4C9EEB),
                  inactiveColor: const Color(0xFF4C9EEB).withValues(alpha: 0.2),
                  onChanged: (val) {
                    setDialogState(() => fontSize = val);
                    ref.read(appPreferencesProvider.notifier).setFontSize(val);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Done', style: TextStyle(color: Color(0xFF4C9EEB), fontWeight: FontWeight.bold)),
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
        content: const Text('Are you sure you want to sign out from your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

/// 1. User Profile & Account Section Widget
class _UserProfileSection extends ConsumerWidget {
  final UserModel user;

  const _UserProfileSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Account Profile'),
        _SectionCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFF4C9EEB),
                    backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                    child: user.profilePhotoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          )
                        : null,
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
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.edit_outlined,
              iconColor: Colors.blue,
              title: 'Edit Profile Details',
              subtitle: 'Name, age, gender, height, weight',
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  final repo = ref.read(userProfileRepositoryProvider);
                  final latestUser = await repo.getUserProfile(user.id);
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading indicator
                    _showEditProfileDialog(context, ref, latestUser ?? user);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading indicator
                    _showEditProfileDialog(context, ref, user); // Fallback
                  }
                }
              },
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.password_outlined,
              iconColor: Colors.orange,
              title: 'Change Password',
              onTap: () => _showChangePasswordDialog(context, ref),
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              titleColor: Colors.red,
              title: 'Delete Account',
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final ageCtrl = TextEditingController(text: user.age?.toString() ?? '');
    final heightCtrl = TextEditingController(text: user.height?.toString() ?? '');
    final weightCtrl = TextEditingController(text: user.weight?.toString() ?? '');
    String? gender = user.gender;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ['Male', 'Female', 'Other', 'Prefer not to say'].contains(gender) ? gender : null,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Male', 'Female', 'Other', 'Prefer not to say']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => gender = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Height (cm/in)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg/lbs)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                      name: nameCtrl.text.isNotEmpty ? nameCtrl.text : null,
                      age: int.tryParse(ageCtrl.text),
                      height: double.tryParse(heightCtrl.text),
                      weight: double.tryParse(weightCtrl.text),
                      gender: gender,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF4C9EEB),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This action is irreversible. All your health data, logs, and insights will be permanently deleted.'),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter Password to Confirm',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (passwordCtrl.text.isEmpty) {
                  setDialogState(() => errorMessage = 'Password is required.');
                  return;
                }
                setDialogState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                try {
                  await ref.read(userProfileNotifierProvider.notifier).deleteAccount(passwordCtrl.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                    errorMessage = e.toString();
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isLoading 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                if (errorMessage != null) const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Current Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'New Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                      setDialogState(() => errorMessage = 'New passwords do not match.');
                      return;
                    }
                    if (newPasswordCtrl.text.length < 6) {
                      setDialogState(() => errorMessage = 'Password must be at least 6 characters.');
                      return;
                    }
                    
                    setDialogState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    
                    try {
                      await ref.read(authActionsProvider.notifier).changePassword(
                        currentPasswordCtrl.text,
                        newPasswordCtrl.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
                      }
                    } catch (e) {
                      setDialogState(() {
                        isLoading = false;
                        errorMessage = e.toString();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF4C9EEB),
                  ),
                  child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update Password', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Helper Utilities for Sections

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor = Colors.grey,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor ?? Colors.black87, fontSize: 16),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 16),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4C9EEB),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdown({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 16),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
