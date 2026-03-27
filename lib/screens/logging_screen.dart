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
  final TextEditingController _sleepHoursCtrl = TextEditingController(text: '0');
  final TextEditingController _sleepMinsCtrl = TextEditingController(text: '0');
  final TextEditingController _mealsCtrl = TextEditingController(text: '0');
  final TextEditingController _waterCtrl = TextEditingController(text: '0.0');
  final TextEditingController _exerciseHoursCtrl = TextEditingController(text: '0');
  final TextEditingController _exerciseMinsCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    _sleepHoursCtrl.dispose();
    _sleepMinsCtrl.dispose();
    _mealsCtrl.dispose();
    _waterCtrl.dispose();
    _exerciseHoursCtrl.dispose();
    _exerciseMinsCtrl.dispose();
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
    
    double parsedSleep = (double.tryParse(_sleepHoursCtrl.text) ?? 0.0) + ((double.tryParse(_sleepMinsCtrl.text) ?? 0.0) / 60.0);
    double parsedWater = double.tryParse(_waterCtrl.text) ?? 0.0;
    int parsedExercise = ((int.tryParse(_exerciseHoursCtrl.text) ?? 0) * 60) + (int.tryParse(_exerciseMinsCtrl.text) ?? 0);

    if (_selectedSymptomType != null) {
      // Combined Symptom + Lifestyle log
      await notifier.submitSymptomLog(
        userId: user.id,
        symptomTypeName: _selectedSymptomType!.name,
        severity: _severity,
        sleepHours: parsedSleep,
        waterIntakeLitres: parsedWater * 0.25, // Convert glasses to litres
        exerciseMinutes: parsedExercise,
        notes: _notesController.text,
      );
    } else {
      // Lifestyle-only log
      await notifier.submitLifestyleEntry(
        userId: user.id,
        sleepHours: parsedSleep,
        dietQualityName: 'balanced', 
        hydrationGlasses: parsedWater.toInt(),
        exerciseMinutes: parsedExercise,
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
            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey.withOpacity(0.1),
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
    final isDark = theme.brightness == Brightness.dark;
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
                      color: isSelected ? Colors.blue.withValues(alpha: isDark ? 0.2 : 0.05) : (theme.cardTheme.color ?? Colors.white),
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
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
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
                    _severity.toStringAsFixed(1),
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
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lifestyle factors', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          _buildLifestyleTile(
            'Sleep Hours',
            'Time spent sleeping',
            Icons.nightlight_round,
            Colors.blue,
            _buildTimeInput(_sleepHoursCtrl, _sleepMinsCtrl, isDark),
            isDark: isDark,
          ),
          _buildLifestyleTile(
            'Meals',
            'Number of meals today',
            Icons.restaurant,
            Colors.orange,
            _buildNumberInput(_mealsCtrl, isDark),
            isDark: isDark,
          ),
          _buildLifestyleTile(
            'Water Intake',
            'Litres',
            Icons.water_drop,
            Colors.green,
            _buildNumberInput(_waterCtrl, isDark, isDouble: true),
            isDark: isDark,
          ),
          _buildLifestyleTile(
            'Exercise',
            'Total workout duration',
            Icons.fitness_center,
            Colors.purple,
            _buildTimeInput(_exerciseHoursCtrl, _exerciseMinsCtrl, isDark),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTile(String title, String subtitle, IconData icon, Color color, Widget inputWidget, {bool isDark = false}) {
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
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            inputWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput(TextEditingController hoursCtrl, TextEditingController minsCtrl, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: hoursCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixText: 'h',
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextField(
            controller: minsCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixText: 'm',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(TextEditingController ctrl, bool isDark, {bool isDouble = false}) {
    return SizedBox(
      width: 70,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
        textAlign: TextAlign.center,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildNotesSelection(ThemeData theme) {
    return SingleChildScrollView(
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
