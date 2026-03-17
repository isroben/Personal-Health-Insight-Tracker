/// ==========================================================================
/// insights_screen.dart — Correlations & Patterns Screen
/// ==========================================================================
/// Displays AI-generated summaries and list of correlations.
/// Features sticky headers and modern card layouts for insights.
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/insight_tile.dart';
import '../models/correlation.dart';
import '../models/symptom_log.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/insight_provider.dart';
import '../providers/subscription_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final isPremium = user?.subscription == SubscriptionTier.premium;
    final insightState = ref.watch(insightProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Insights & Patterns'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(insightProvider.notifier).refreshInsights(),
          child: CustomScrollView(
            slivers: [
              // ── AI Analysis Section (Gated) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isPremium 
                    ? _buildAiAnalysisCard(context, insightState)
                    : _buildLockedAiCard(context, ref),
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

              // ── Correlation List (from Provider) ──
              insightState.when(
                data: (correlations) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: correlations.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('No patterns detected yet. Log more data!')),
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
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e')),
                ),
              ),

              // ── Timeline Header ──
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Symptom Timeline',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ── Timeline Placeholder ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Text('fl_chart timeline will render here')),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAnalysisCard(BuildContext context, AsyncValue<List<Correlation>> state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text('AI Weekly Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Keep logging your symptoms. Every 7 days, our AI will generate a personalized summary of your health trends and trigger patterns.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedAiCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 32, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Premium AI Insights Locked', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Unlock advanced plain-language pattern analysis and predictive alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(subscriptionActionsProvider.notifier).upgradeToPremium();
            },
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }
}

