/// ==========================================================================
/// home_screen.dart — Dashboard / Landing Screen
/// ==========================================================================
/// The primary dashboard displaying:
/// - Health Score (Gamification/vibe check)
/// - Trend arrows (improving/declining)
/// - Symptom summary (recent logs)
///
/// Features clean animations and premium styling.
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gamification_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            child: Icon(Icons.person, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              ref.invalidate(wellnessScoreProvider(user.id));
              ref.invalidate(streakProvider(user.id));
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting & Date ──
                Text(
                  'Good morning, ${user?.name.split(' ')[0] ?? 'Explorer'}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Tuesday, March 18', // In a real app, use intl to format DateTime.now()
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Health Score Card ──
                if (user != null)
                   _HealthScoreCard(userId: user.id)
                else
                   const _HealthScoreCard(), // Fallback/Loading
                
                const SizedBox(height: 24),

                // ── Recent Logs Summary ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Logs',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to History tab (if exists) or expand
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentLogsColumn(theme),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      // ── Quick Log FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open Log screen directly or trigger log modal
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Entry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRecentLogsColumn(ThemeData theme) {
    // Dummy Data for UI preview
    return Column(
      children: [
        _buildLogItem('Headache', 'Severity: 4/10', '2 hrs ago', theme),
        _buildLogItem('Fatigue', 'Severity: 7/10', 'Yesterday', theme),
        _buildLogItem('Poor Sleep', '4.5 hours | High Stress', 'Oct 10', theme),
      ],
    );
  }

  Widget _buildLogItem(String title, String subtitle, String time, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.medical_services_outlined,
              color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(time, style: theme.textTheme.bodySmall),
      ),
    );
  }
}

class _HealthScoreCard extends ConsumerWidget {
  final String? userId;
  const _HealthScoreCard({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch dynamic data
    final scoreAsync = userId != null 
        ? ref.watch(wellnessScoreProvider(userId!))
        : const AsyncValue<int>.data(82); // Fallback
        
    final streakAsync = userId != null
        ? ref.watch(streakProvider(userId!))
        : const AsyncValue<int>.data(5);

    final score = scoreAsync.value ?? 0;
    final streak = streakAsync.value ?? 0;
    const isImproving = true; // Still mocked for UI demo

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.health_and_safety,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wellness Score',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fireplace, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$streak Day Streak',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ 100',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isImproving ? Icons.trending_up : Icons.trending_down,
                          color: isImproving ? Colors.greenAccent : Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isImproving ? '+5% this week' : '-2% this week',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                score >= 80 
                  ? 'Excellent job! Your consistency is paying off.' 
                  : 'You\'re on the right track! Try logging more lifestyle details.',
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
