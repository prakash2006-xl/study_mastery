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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showAddEventDialog(context, ref),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: scheduleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
                data: (allItems) {
                  final now = DateTime.now();
                  final items = allItems.where((item) => 
                    item.scheduledTime.year == now.year && 
                    item.scheduledTime.month == now.month && 
                    item.scheduledTime.day == now.day
                  ).toList();
                  
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
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => ref.read(scheduleItemNotifierProvider.notifier).deleteScheduleItem(item.id),
                              child: const Icon(Icons.close, color: Colors.grey, size: 16),
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

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Event'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Time: ${selectedTime.format(context)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: selectedTime);
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final now = DateTime.now();
                      final dt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                      ref.read(scheduleItemNotifierProvider.notifier).addScheduleItem(titleController.text, dt);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
