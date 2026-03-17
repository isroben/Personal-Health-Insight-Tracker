/// ==========================================================================
/// logging_screen.dart — Symptom & Lifestyle Logging Screen
/// ==========================================================================
/// Fast, <30s logging flow.
/// Features:
/// - Quick-select symptom chips
/// - Animated severity slider
/// - Expandable notes section
/// - Daily lifestyle sliders (sleep, diet, hydration, stress)
/// ==========================================================================

import 'package:flutter/material.dart';
import '../widgets/lifestyle_slider.dart';

class LoggingScreen extends StatefulWidget {
  const LoggingScreen({super.key});

  @override
  State<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends State<LoggingScreen> {
  // Symptom State
  String? _selectedSymptom;
  double _severity = 5.0;
  bool _showNotes = false;
  final TextEditingController _notesController = TextEditingController();

  // Lifestyle State
  double _sleepHours = 7.0;
  double _stressLevel = 3.0;
  double _hydration = 4.0;
  double _exerciseMins = 30.0;

  final List<String> _commonSymptoms = [
    'Headache',
    'Migraine',
    'Fatigue',
    'Nausea',
    'Bloating',
    'Brain Fog',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Log Entry'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Close if opened as modal
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Symptom Selection ──
              _buildSectionHeader('What are you experiencing?', Icons.sick_outlined, theme),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonSymptoms.map((symptom) {
                  final isSelected = _selectedSymptom == symptom;
                  return FilterChip(
                    label: Text(symptom),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSymptom = selected ? symptom : null);
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  // TODO: Open full symptom search
                },
                icon: const Icon(Icons.add),
                label: const Text('Other symptom...'),
              ),

              // ── 2. Severity (Animated conditional) ──
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _selectedSymptom == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            'Severity: ${_severity.toInt()}/10',
                            Icons.speed,
                            theme,
                          ),
                          Slider(
                            value: _severity,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: _getSeverityColor(_severity),
                            onChanged: (val) => setState(() => _severity = val),
                          ),
                          // Notes toggle
                          Row(
                            children: [
                              Checkbox(
                                value: _showNotes,
                                onChanged: (val) =>
                                    setState(() => _showNotes = val ?? false),
                              ),
                              const Text('Add context/notes (optional)'),
                            ],
                          ),
                          if (_showNotes)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  hintText: 'What triggered this? Any meds taken?',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ),
                        ],
                      ),
              ),
              const Divider(height: 48),

              // ── 3. Daily Lifestyle ──
              _buildSectionHeader('Daily Lifestyle', Icons.directions_run, theme),
              const SizedBox(height: 16),
              LifestyleSlider(
                label: 'Sleep',
                unit: 'hrs',
                icon: Icons.bedtime_outlined,
                value: _sleepHours,
                min: 0,
                max: 14,
                divisions: 28, // Half-hour increments
                onChanged: (v) => setState(() => _sleepHours = v),
              ),
              const SizedBox(height: 8),
              LifestyleSlider(
                label: 'Stress',
                unit: '/ 10',
                icon: Icons.psychology_outlined,
                value: _stressLevel,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => setState(() => _stressLevel = v),
              ),
              const SizedBox(height: 8),
              LifestyleSlider(
                label: 'Hydration',
                unit: 'glasses',
                icon: Icons.water_drop_outlined,
                value: _hydration,
                min: 0,
                max: 15,
                divisions: 15,
                onChanged: (v) => setState(() => _hydration = v),
              ),
              const SizedBox(height: 8),
              LifestyleSlider(
                label: 'Exercise',
                unit: 'mins',
                icon: Icons.fitness_center_outlined,
                value: _exerciseMins,
                min: 0,
                max: 120,
                divisions: 12, // 10-min increments
                onChanged: (v) => setState(() => _exerciseMins = v),
              ),
              const SizedBox(height: 32),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedSymptom == null
                      ? null
                      : () {
                          // TODO: Validate and save to Riverpod provider
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Log saved successfully!')),
                          );
                        },
                  child: const Text('Save Entry', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(double severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.orange;
    return Colors.red;
  }
}
