import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/gamification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/symptom_log.dart';
import '../routes/app_router.dart';
import '../services/gamification_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              ref.invalidate(wellnessScoreProvider(user.id));
              ref.read(symptomLogsProvider.notifier).fetchLogs(user.id);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 800 ? (screenWidth - 800)/2 : 20,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user?.name ?? 'Sarah', theme),
                const SizedBox(height: 32),
                _HealthScoreCard(userId: user?.id),
                const SizedBox(height: 32),
                Text(
                  "Today's Summary",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryGrid(ref, isDesktop, isTablet, user?.id),
                const SizedBox(height: 32),
                Text(
                  "Today's Activity",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActivityTimeline(ref, theme),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the log entry panel (fullscreen dialog)
          Navigator.pushNamed(context, AppRouter.logRoute);
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(String name, ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17) greeting = 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          name.split(' ')[0],
          style: theme.textTheme.headlineLarge,
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(WidgetRef ref, bool isDesktop, bool isTablet, String? userId) {
    if (userId == null) return const SizedBox.shrink();

    final summaryAsync = ref.watch(todaySummaryProvider(userId));

    return summaryAsync.when(
      data: (data) {
        int crossAxisCount = 3;
        if (isDesktop) crossAxisCount = 5;
        else if (isTablet) crossAxisCount = 4;

        final sleepHours = data['sleep'] as double;
        final hydrationLitres = data['hydration'] as double;
        final stressLabel = data['stress'] as String;
        final exerciseMins = data['exercise'] as int;
        final screenTimeMins = data['screen_time'] as int? ?? 0;

        final summaryItems = [
          _SummaryItem(
            label: 'Sleep', 
            value: '${sleepHours.toStringAsFixed(1)}h', 
            icon: Icons.nightlight_round, 
            color: Colors.indigo
          ),
          _SummaryItem(
            label: 'Hydration', 
            value: '${(hydrationLitres / 0.25).round()}/8', 
            icon: Icons.water_drop, 
            color: Colors.cyan
          ),
          _SummaryItem(
            label: 'Stress', 
            value: stressLabel, 
            icon: Icons.bolt, 
            color: Colors.orange
          ),
          _SummaryItem(
            label: 'Exercise', 
            value: '${exerciseMins}m', 
            icon: Icons.fitness_center, 
            color: Colors.blueAccent
          ),
          _SummaryItem(
            label: 'Screen', 
            value: screenTimeMins > 60 
                ? '${(screenTimeMins / 60).floor()}h ${screenTimeMins % 60}m'
                : '${screenTimeMins}m', 
            icon: Icons.computer, 
            color: Colors.purple
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: summaryItems.length,
          itemBuilder: (context, index) {
            final item = summaryItems[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 16, color: item.color),
                    ),
                    const SizedBox(height: 2),
                    Text(item.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildActivityTimeline(WidgetRef ref, ThemeData theme) {
    final logsAsync = ref.watch(symptomLogsProvider);

    return logsAsync.when(
      data: (logs) {
        final now = DateTime.now();
        final todayLogs = logs.where((l) => 
          l.date.year == now.year && l.date.month == now.month && l.date.day == now.day
        ).take(5).toList();

        if (todayLogs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No activity logged today yet.'),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: List.generate(todayLogs.length, (index) {
                final log = todayLogs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (index != todayLogs.length - 1)
                            Container(
                              width: 2,
                              height: 40,
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(log.date),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${log.symptomType.displayName} logged',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (log.notes != null && log.notes!.isNotEmpty)
                              Text(
                                log.notes!,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _HealthScoreCard extends ConsumerWidget {
  final String? userId;
  const _HealthScoreCard({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch the health trend provider for real-time score and label
    final trendAsync = userId != null 
        ? ref.watch(healthTrendProvider(userId!))
        : const AsyncValue<HealthTrend>.loading(); 
    
    return trendAsync.when(
      data: (trend) => _buildCard(context, theme, trend.score.round(), trend.label),
      loading: () => _buildCard(context, theme, 0, 'Calculating...', isLoading: true),
      error: (e, _) => _buildCard(context, theme, 0, 'Error: $e'),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, int score, String label, {bool isLoading = false}) {
    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.trending_flat;

    if (label == 'Improving') {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else if (label == 'Declining') {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      else
                        Text(
                          '$score',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text('/100', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: trendColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(color: trendColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(trendIcon, color: trendColor, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
