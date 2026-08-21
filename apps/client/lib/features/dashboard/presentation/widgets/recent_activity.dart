import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_provider.dart';

class RecentActivityPanel extends ConsumerWidget {
  const RecentActivityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityLogNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: activityAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text('No recent activity.', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final diff = DateTime.now().difference(log.createdAt);
                      String timeAgo = '';
                      if (diff.inHours > 0) {
                        timeAgo = '\${diff.inHours}h ago';
                      } else if (diff.inMinutes > 0) {
                        timeAgo = '\${diff.inMinutes}m ago';
                      } else {
                        timeAgo = 'Just now';
                      }

                      IconData icon = Icons.info_outline;
                      Color iconColor = Colors.grey;
                      
                      switch (log.iconType) {
                        case 'task': 
                          icon = Icons.check; 
                          iconColor = Colors.green; 
                          break;
                        case 'document': 
                          icon = Icons.library_books; 
                          iconColor = Colors.blue; 
                          break;
                        case 'timer': 
                          icon = Icons.timer; 
                          iconColor = Colors.purpleAccent; 
                          break;
                      }

                      return Row(
                        children: [
                          Icon(icon, size: 16, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
