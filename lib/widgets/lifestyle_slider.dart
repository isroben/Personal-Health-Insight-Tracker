/// ==========================================================================
/// lifestyle_slider.dart — Reusable Slider Widget for Lifestyle Inputs
/// ==========================================================================
/// A labeled slider component for numerical lifestyle metrics:
/// - Sleep hours (0–24)
/// - Stress level (1–10)
/// - Exercise minutes (0–180)
/// - Hydration glasses (0–20)
///
/// Features a label, current value display, and customizable range.
/// Used on: LoggingScreen
/// ==========================================================================

import 'package:flutter/material.dart';

class LifestyleSlider extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final IconData? icon;

  const LifestyleSlider({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label Row ──
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(label, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} $unit',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // ── Slider ──
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toStringAsFixed(
                  value == value.roundToDouble() ? 0 : 1),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
