/// ==========================================================================
/// insights_screen.dart — Correlations & Patterns Screen
/// ==========================================================================
/// Displays AI-generated summaries and list of correlations.
/// Features sticky headers and modern card layouts for insights.
/// ==========================================================================

import 'package:flutter/material.dart';
import '../widgets/insight_tile.dart';
import '../models/correlation.dart';
import '../models/symptom_log.dart'; // For SymptomType enum

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dummy Data for UI preview
    final dummyCorrelations = [
      Correlation(
        id: '1',
        userId: 'u1',
        symptom: SymptomType.headache,
        trigger: 'Low Sleep (< 5 hrs)',
        frequency: 4,
        severityCorrelation: 0.85,
        summary: 'Your headaches strongly correlate with days you sleep less than 5 hours.',
        detectedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Correlation(
        id: '2',
        userId: 'u1',
        symptom: SymptomType.fatigue,
        trigger: 'High Stress (> 7)',
        frequency: 6,
        severityCorrelation: 0.60,
        summary: 'Consistent high stress usually precedes fatigue the following day.',
        detectedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Insights & Patterns'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about how AI generates insights
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AI Summary Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'AI Weekly Analysis',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This week, your sleep has improved by 15%, leading to a noticeable drop in severe headaches. However, keep an eye on your hydration levels, which trended downward on busy days.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Top Triggers Header ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Top Triggers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ── Correlation List ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final c = dummyCorrelations[index];
                    return InsightTile(
                      correlation: c,
                      onTap: () {
                        // Show detailed chart for this correlation
                      },
                    );
                  },
                  childCount: dummyCorrelations.length,
                ),
              ),
            ),

            // ── Placeholder for Charts ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Symptom Timeline',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('fl_chart timeline will render here'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
