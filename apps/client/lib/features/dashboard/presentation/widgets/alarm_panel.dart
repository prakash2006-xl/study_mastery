import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/dashboard_provider.dart';

class AlarmPanel extends ConsumerWidget {
  const AlarmPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Alarms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      final now = DateTime.now();
                      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                      ref.read(alarmNotifierProvider.notifier).addAlarm('New Alarm', dt);
                    }
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: alarmsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
                data: (alarms) {
                  if (alarms.isEmpty) {
                    return const Center(child: Text('No alarms set.', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    itemCount: alarms.length,
                    separatorBuilder: (context, index) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final alarm = alarms[index];
                      final timeStr = DateFormat('hh:mm a').format(alarm.time);
                      
                      return Row(
                        children: [
                          Icon(
                            Icons.notifications_active, 
                            color: alarm.isEnabled ? Theme.of(context).colorScheme.primary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: alarm.isEnabled ? Colors.white : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  alarm.label,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: alarm.isEnabled,
                            onChanged: (val) => ref.read(alarmNotifierProvider.notifier).toggleAlarm(alarm),
                            activeColor: Theme.of(context).colorScheme.primary,
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
