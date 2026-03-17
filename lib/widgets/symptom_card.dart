/// ==========================================================================
/// symptom_card.dart — Reusable Symptom Display Card
/// ==========================================================================
/// Displays a single symptom log entry with:
/// - Symptom type icon & label
/// - Severity indicator (color-coded bar or dots)
/// - Date & optional notes
///
/// Used on: HomeScreen (recent logs), InsightsScreen (detail view)
/// ==========================================================================

import 'package:flutter/material.dart';
import '../models/symptom_log.dart';

class SymptomCard extends StatelessWidget {
  final SymptomLog log;
  final VoidCallback? onTap;

  const SymptomCard({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _severityColor(log.severity).withValues(alpha: 0.2),
          child: Icon(
            _symptomIcon(log.symptomType),
            color: _severityColor(log.severity),
          ),
        ),
        title: Text(_symptomLabel(log.symptomType)),
        subtitle: Text(
          log.notes ?? 'No notes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${log.severity}/10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _severityColor(log.severity),
              ),
            ),
            Text(
              _formatDate(log.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Maps severity (1–10) to a color gradient: green → yellow → red.
  Color _severityColor(int severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.orange;
    return Colors.red;
  }

  /// Returns a descriptive label for each symptom type.
  String _symptomLabel(SymptomType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  /// Returns an icon for each symptom type.
  IconData _symptomIcon(SymptomType type) {
    // TODO: Map each SymptomType to a specific icon
    return Icons.medical_services_outlined;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
