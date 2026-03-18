/// ==========================================================================
/// insights_screen.dart — Correlations & Patterns Screen
/// ==========================================================================
/// Displays AI-generated summaries, correlation bar charts, and symptom
/// timeline charts.
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/insight_tile.dart';
import '../models/correlation.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/insight_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/subscription_provider.dart';
import '../charts/symptom_timeline_chart.dart';
import '../charts/correlation_bar_chart.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final isPremium = user?.subscription == SubscriptionTier.premium;
    final insightState = ref.watch(insightProvider);
    final symptomLogsState = ref.watch(symptomLogsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Insights & Patterns'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(insightProvider.notifier).refreshInsights(),
            tooltip: 'Recalculate patterns',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
             await ref.read(insightProvider.notifier).refreshInsights();
          },
          child: CustomScrollView(
            slivers: [
              // ── AI Analysis Section (Gated) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isPremium 
                    ? _buildAiAnalysisCard(context, ref, insightState)
                    : _buildLockedAiCard(context, ref),
                ),
              ),

              // ── Top Triggers Header ──
              _buildSectionHeader(theme, 'Trigger Strength (Correlation)'),

              // ── Correlation Bar Chart ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: insightState.when(
                    data: (correlations) => correlations.isEmpty
                        ? const Center(child: Text('Not enough data for triggers yet.'))
                        : CorrelationBarChart(correlations: correlations),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error loading charts: $e')),
                  ),
                ),
              ),

              // ── Top Triggers List ──
              _buildSectionHeader(theme, 'Detected Patterns'),
              insightState.when(
                data: (correlations) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: correlations.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('Log more data to see patterns.')),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => InsightTile(
                              correlation: correlations[index],
                              onTap: () {},
                            ),
                            childCount: correlations.length,
                          ),
                        ),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // ── Timeline Header ──
              _buildSectionHeader(theme, 'Symptom Timeline (7 Days)'),

              // ── Timeline Chart ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: symptomLogsState.when(
                    data: (logs) => SymptomTimelineChart(logs: logs, days: 7),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAiAnalysisCard(BuildContext context, WidgetRef ref, AsyncValue<List<Correlation>> state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Premium AI Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.psychology_alt, size: 20),
                onPressed: () => ref.read(insightProvider.notifier).requestAiInsights(),
                tooltip: 'Run AI Analysis',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your logs suggest that poor sleep (<6hrs) precedes your migraines with 80% frequency. Try maintaining a consistent sleep schedule this week.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedAiCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_person_outlined, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock AI Trigger Predictions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Get plain-language summaries and advanced correlation analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
               ref.read(subscriptionActionsProvider.notifier).upgradeToPremium();
            },
            child: const Text('Go Premium'),
          ),
        ],
      ),
    );
  }
}
