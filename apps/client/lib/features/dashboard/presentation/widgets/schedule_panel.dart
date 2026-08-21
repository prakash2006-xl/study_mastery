import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/dashboard_provider.dart';

class SchedulePanel extends ConsumerWidget {
  const SchedulePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleItemNotifierProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: scheduleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No schedule for today.', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final timeStr = DateFormat('hh:mm a').format(item.scheduledTime);
                      final bool isPast = item.scheduledTime.isBefore(DateTime.now()) && !item.isCompleted;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: item.isCompleted ? Colors.grey : Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 24,
                              color: item.isCompleted 
                                  ? theme.colorScheme.tertiary 
                                  : (isPast ? Colors.orange : theme.colorScheme.primary),
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: item.isCompleted ? Colors.grey : Colors.white,
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref.read(scheduleItemNotifierProvider.notifier).toggleScheduleItem(item),
                              child: Icon(
                                item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: item.isCompleted ? theme.colorScheme.tertiary : Colors.grey,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View full calendar', style: TextStyle(color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
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
