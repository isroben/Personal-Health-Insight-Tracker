import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedCondition;
  late MeasurementUnit _selectedUnit;

  final List<String> _conditions = [
    'General Wellness',
    'Migraine Management',
    'IBS / Digestive Health',
    'Sleep Optimization',
    'Stress Reduction',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value!;
    _nameController = TextEditingController(text: user.name);
    _selectedCondition = user.preferences.primaryCondition;
    _selectedUnit = user.preferences.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value!;
    final updatedPrefs = user.preferences.copyWith(
      primaryCondition: _selectedCondition,
      unit: _selectedUnit,
    );

    await ref.read(userProfileNotifierProvider.notifier).updateProfile(
      name: _nameController.text,
      preferences: updatedPrefs.toMap(),
    );

    if (mounted && !ref.read(userProfileNotifierProvider).hasError) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (state.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.person, size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text('Basic Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Name cannot be empty' : null,
              ),

              const SizedBox(height: 32),
              Text('Health Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Primary Goal / Condition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCondition = v!),
              ),
              const SizedBox(height: 16),
              
              Text('Measurement Units', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<MeasurementUnit>(
                segments: const [
                  ButtonSegment(value: MeasurementUnit.metric, label: Text('Metric (kg, cm)')),
                  ButtonSegment(value: MeasurementUnit.imperial, label: Text('Imperial (lb, in)')),
                ],
                selected: {_selectedUnit},
                onSelectionChanged: (v) => setState(() => _selectedUnit = v.first),
              ),
              
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(state.error.toString(), style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
