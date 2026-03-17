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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false, // Left aligned for modern feel
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
            // TODO: Refresh data provider
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting & Date ──
                Text(
                  'Good morning, Alex',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Thursday, October 12',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Health Score Card ──
                const _HealthScoreCard(),
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

/// A visually appealing card showing an overall health score and trend arrows.
class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dummy state values
    const score = 82;
    const isImproving = true;

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
          // Background decorative element (Glassmorphism hint)
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
              Text(
                'Wellness Score',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
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
                  // Trend indicator
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
              const Text(
                'Great job! Your sleep consistency is paying off. Keep it up.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
