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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/logging_provider.dart';
import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../widgets/lifestyle_slider.dart';
import '../services/logging_service.dart'; // Added this import for LogResult

class LoggingScreen extends ConsumerStatefulWidget {
  final SymptomLog? existingLog;
  const LoggingScreen({super.key, this.existingLog});

  @override
  ConsumerState<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends ConsumerState<LoggingScreen> {
  // Symptom State
  SymptomType? _selectedSymptomType;
  double _severity = 5.0;
  bool _showNotes = false;
  final TextEditingController _notesController = TextEditingController();

  // Lifestyle State
  double _sleepHours = 7.0;
  double _stressLevel = 3.0;
  int _hydration = 4;
  int _exerciseMins = 30;
  DietQuality _dietQuality = DietQuality.fair;

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _selectedSymptomType = widget.existingLog!.symptomType;
      _severity = widget.existingLog!.severity.toDouble();
      if (widget.existingLog!.notes != null && widget.existingLog!.notes!.isNotEmpty) {
        _showNotes = true;
        _notesController.text = widget.existingLog!.notes!;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to log entries.')),
      );
      return;
    }

    final service = ref.read(loggingServiceProvider);
    final notifier = ref.read(loggingStateProvider.notifier);

    // 1. Log/Update Symptom (if selected)
    if (_selectedSymptomType != null) {
      LogResult symptomResult;
      if (widget.existingLog != null) {
        symptomResult = await service.updateSymptomLog(
          existingLog: widget.existingLog!,
          newSeverity: _severity,
          newNotes: _showNotes ? _notesController.text : null,
        );
      } else {
        symptomResult = await notifier.submitSymptomLog(
          userId: user.id,
          symptomTypeName: _selectedSymptomType!.name,
          severity: _severity,
          notes: _showNotes ? _notesController.text : null,
        );
      }

      if (!symptomResult.success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(symptomResult.message ?? 'Failed to log symptom.')),
          );
        }
        return;
      }
    }

    // 2. Log Lifestyle (Only if not editing a specific past symptom log)
    if (widget.existingLog == null) {
      final lifestyleResult = await notifier.submitLifestyleEntry(
        userId: user.id,
        sleepHours: _sleepHours,
        dietQualityName: _dietQuality.name,
        hydrationGlasses: _hydration,
        exerciseMinutes: _exerciseMins,
        stressLevel: _stressLevel,
      );

      if (!lifestyleResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lifestyleResult.message ?? 'Failed to save lifestyle.')),
        );
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingLog != null ? 'Log updated!' : 'Logs saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logState = ref.watch(loggingStateProvider);
    final isEditing = widget.existingLog != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Log' : 'Log Today\'s Health'),
      ),
      body: SafeArea(
        child: logState.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator()),
          orElse: () => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Symptom Selection ──
                _buildSectionHeader(isEditing ? 'Symptom' : 'Any symptoms today?', Icons.sick_outlined, theme),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SymptomType.values.map((type) {
                    final isSelected = _selectedSymptomType == type;
                    return FilterChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: isEditing ? null : (selected) {
                        setState(() => _selectedSymptomType = selected ? type : null);
                      },
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: theme.colorScheme.primary,
                    );
                  }).toList(),
                ),

                // ── 2. Severity (Animated conditional) ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _selectedSymptomType == null
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
                                const Text('Add notes (triggers, meds, etc.)'),
                              ],
                            ),
                            if (_showNotes)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g., "Drank coffee late", "Took Ibuprofen"',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                          ],
                        ),
                ),
                
                if (!isEditing) ...[
                  const Divider(height: 48),

                  // ── 3. Daily Lifestyle ──
                  _buildSectionHeader('Daily Factors', Icons.directions_run, theme),
                  const SizedBox(height: 16),
                  LifestyleSlider(
                    label: 'Sleep',
                    unit: 'hrs',
                    icon: Icons.bedtime_outlined,
                    value: _sleepHours,
                    min: 0,
                    max: 14,
                    divisions: 28,
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
                    value: _hydration.toDouble(),
                    min: 0,
                    max: 15,
                    divisions: 15,
                    onChanged: (v) => setState(() => _hydration = v.toInt()),
                  ),
                  const SizedBox(height: 8),
                  LifestyleSlider(
                    label: 'Exercise',
                    unit: 'mins',
                    icon: Icons.fitness_center_outlined,
                    value: _exerciseMins.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: 12,
                    onChanged: (v) => setState(() => _exerciseMins = v.toInt()),
                  ),
                  const SizedBox(height: 24),
                  
                  // Diet Quality
                  Text('Diet Quality', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<DietQuality>(
                    segments: DietQuality.values.map((q) {
                      return ButtonSegment(
                        value: q,
                        label: Text(q.displayName),
                        icon: Text(q.emoji),
                      );
                    }).toList(),
                    selected: {_dietQuality},
                    onSelectionChanged: (newSelection) {
                      setState(() => _dietQuality = newSelection.first);
                    },
                  ),
                ],
                const SizedBox(height: 40),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _handleSave,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Update Entry' : 'Save Entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
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
