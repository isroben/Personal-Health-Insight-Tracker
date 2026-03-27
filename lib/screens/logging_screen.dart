import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/logging_provider.dart';
import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../services/logging_service.dart';

class LoggingScreen extends ConsumerStatefulWidget {
  final SymptomLog? existingLog;
  const LoggingScreen({super.key, this.existingLog});

  @override
  ConsumerState<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends ConsumerState<LoggingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Symptom State
  SymptomType? _selectedSymptomType;
  double _severity = 5.0;
  final TextEditingController _notesController = TextEditingController();

  // Lifestyle State
  double _sleepHours = 7.0;
  int _meals = 3;
  int _waterIntake = 6;
  int _exerciseMins = 30;

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSave();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSave() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
      return;
    }

    final notifier = ref.read(loggingStateProvider.notifier);
    
    if (_selectedSymptomType != null) {
      // Combined Symptom + Lifestyle log
      await notifier.submitSymptomLog(
        userId: user.id,
        symptomTypeName: _selectedSymptomType!.name,
        severity: _severity,
        sleepHours: _sleepHours,
        waterIntakeLitres: _waterIntake * 0.25, // Convert glasses to litres
        exerciseMinutes: _exerciseMins,
        notes: _notesController.text,
      );
    } else {
      // Lifestyle-only log
      await notifier.submitLifestyleEntry(
        userId: user.id,
        sleepHours: _sleepHours,
        dietQualityName: 'balanced', 
        hydrationGlasses: _waterIntake,
        exerciseMinutes: _exerciseMins,
        stressLevel: 5.0,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quick Log'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _prevStep,
              child: const Text('Back'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          _buildSymptomSelection(theme),
          _buildSeveritySelection(theme),
          _buildLifestyleFactors(theme),
          _buildNotesSelection(theme),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: (_currentStep == 0 && _selectedSymptomType == null) ? null : _nextStep,
                child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 12),
                   child: Text(_currentStep == _totalSteps - 1 ? 'Save Log' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomSelection(ThemeData theme) {
    final List<Map<String, dynamic>> items = [
      {'type': SymptomType.headache, 'icon': Icons.psychology, 'color': Colors.blue},
      {'type': SymptomType.fatigue, 'icon': Icons.coffee, 'color': Colors.green},
      {'type': SymptomType.stress, 'icon': Icons.bolt, 'color': Colors.orange},
      {'type': SymptomType.pain, 'icon': Icons.favorite, 'color': Colors.red},
      {'type': SymptomType.other, 'icon': Icons.more_horiz, 'color': Colors.purple},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you feeling?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final type = item['type'] as SymptomType;
                final isSelected = _selectedSymptomType == type;

                return GestureDetector(
                  onTap: () => setState(() => _selectedSymptomType = type),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item['color'].withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'], color: item['color'], size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          type.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelection(ThemeData theme) {
    String severityLabel = 'Moderate';
    if (_severity < 4) severityLabel = 'Mild';
    if (_severity > 7) severityLabel = 'Severe';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How severe is it?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 48),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    _severity.toInt().toString(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(severityLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 40),
                  Slider(
                    value: _severity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => setState(() => _severity = v),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 - Mild', style: TextStyle(fontSize: 12)),
                        Text('10 - Severe', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleFactors(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lifestyle factors', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          _buildLifestyleTile(
            'Sleep Hours',
            '${_sleepHours.toInt()} hours',
            Icons.nightlight_round,
            Colors.blue,
            _sleepHours.toInt(),
            (v) => setState(() => _sleepHours = v.toDouble()),
          ),
          _buildLifestyleTile(
            'Meals',
            '$_meals meals today',
            Icons.restaurant,
            Colors.orange,
            _meals,
            (v) => setState(() => _meals = v),
          ),
          _buildLifestyleTile(
            'Water Intake',
            '$_waterIntake glasses',
            Icons.water_drop,
            Colors.green,
            _waterIntake,
            (v) => setState(() => _waterIntake = v),
          ),
          _buildLifestyleTile(
            'Exercise',
            '$_exerciseMins minutes',
            Icons.fitness_center,
            Colors.purple,
            _exerciseMins,
            (v) => setState(() => _exerciseMins = v),
            step: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTile(String title, String subtitle, IconData icon, Color color, int value, ValueChanged<int> onChanged, {int step = 1}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _buildCustomStepper(value, onChanged, step),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomStepper(int value, ValueChanged<int> onChanged, int step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: () => onChanged(value + step),
                child: const Icon(Icons.keyboard_arrow_up, size: 16),
              ),
              GestureDetector(
                onTap: () => onChanged(value > 0 ? value - step : 0),
                child: const Icon(Icons.keyboard_arrow_down, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSelection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add notes (optional)', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _notesController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Add any additional notes about how you\'re feeling...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Optional: Voice input available in settings',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
