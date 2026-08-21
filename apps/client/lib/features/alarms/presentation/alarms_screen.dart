import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../dashboard/application/dashboard_provider.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add),
        label: const Text('Add Alarm'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Alarms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            sliver: alarmsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, st) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
              data: (alarms) {
                if (alarms.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No alarms set.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alarm = alarms[index];
                      final timeStr = DateFormat('hh:mm a').format(alarm.time);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: alarm.isEnabled ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    alarm.label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: alarm.isEnabled ? theme.colorScheme.primary : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Switch(
                                value: alarm.isEnabled,
                                onChanged: (val) => ref.read(alarmNotifierProvider.notifier).toggleAlarm(alarm),
                                activeColor: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () {
                                  ref.read(alarmNotifierProvider.notifier).deleteAlarm(alarm.id);
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: alarms.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
