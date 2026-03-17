/// ==========================================================================
/// insight_tile.dart — Insight / Correlation Display Tile
/// ==========================================================================
/// Displays a single detected correlation between a symptom and a trigger.
/// Shows:
/// - Symptom name & trigger description
/// - Correlation strength badge (Weak / Moderate / Strong)
/// - Frequency count
/// - Optional AI-generated summary (premium)
///
/// Used on: InsightsScreen, HomeScreen (top insights)
/// ==========================================================================

import 'package:flutter/material.dart';
import '../models/correlation.dart';

class InsightTile extends StatelessWidget {
  final Correlation correlation;
  final VoidCallback? onTap;

  const InsightTile({super.key, required this.correlation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ──
              Row(
                children: [
                  // Symptom label
                  Expanded(
                    child: Text(
                      '${_capitalize(correlation.symptom.name)} ↔ ${correlation.trigger}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Strength badge
                  _StrengthBadge(label: correlation.strengthLabel),
                ],
              ),
              const SizedBox(height: 8),

              // ── Details ──
              Text(
                'Observed ${correlation.frequency} times',
                style: theme.textTheme.bodySmall,
              ),

              // ── AI Summary (premium) ──
              if (correlation.summary != null) ...[
                const SizedBox(height: 8),
                Text(
                  correlation.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

/// Small badge showing correlation strength with appropriate color.
class _StrengthBadge extends StatelessWidget {
  final String label;
  const _StrengthBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Strong' => Colors.red,
      'Moderate' => Colors.orange,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
