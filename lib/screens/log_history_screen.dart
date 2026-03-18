import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/symptom_provider.dart';
import '../providers/auth_provider.dart';
import '../models/symptom_log.dart';
import '../routes/app_router.dart';

class LogHistoryScreen extends ConsumerStatefulWidget {
  const LogHistoryScreen({super.key});

  @override
  ConsumerState<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends ConsumerState<LogHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(symptomLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = ref.read(authStateProvider).valueOrNull;
              if (user != null) {
                ref.read(symptomLogsProvider.notifier).fetchLogs(user.id);
              }
            },
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  const Text('No logs found. Start logging today!'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRouter.logRoute),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Log'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _LogHistoryItem(log: log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _LogHistoryItem extends ConsumerWidget {
  final SymptomLog log;
  const _LogHistoryItem({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(log.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(log.severity).withOpacity(0.1),
          child: Text(
            '${log.severity}',
            style: TextStyle(
              color: _getSeverityColor(log.severity),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          log.symptomType.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateStr, style: theme.textTheme.bodySmall),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.pushNamed(context, AppRouter.logRoute, arguments: log);
            } else if (value == 'delete') {
              _confirmDelete(context, ref, log);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.orange;
    return Colors.red;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SymptomLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text('Are you sure you want to delete this entry? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(symptomLogsProvider.notifier).deleteLog(log.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
