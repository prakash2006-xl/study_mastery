import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/dashboard_provider.dart';
import '../../../tasks/application/task_provider.dart';

class SummaryCardsRow extends ConsumerWidget {
  const SummaryCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch real data
    final tasksState = ref.watch(taskNotifierProvider);
    final sessionsState = ref.watch(studySessionNotifierProvider);

    // 2. Compute Tasks stats
    int tasksToday = 0;
    int completedToday = 0;
    int totalCompleted = 0;

    tasksState.whenData((tasks) {
      final now = DateTime.now();
      for (final t in tasks) {
        if (t.isCompleted) totalCompleted++;
        if (t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day) {
          tasksToday++;
          if (t.isCompleted) completedToday++;
        }
      }
    });

    final taskProgress = tasksToday > 0 ? (completedToday / tasksToday) : 0.0;
    final taskProgressStr = '${(taskProgress * 100).toInt()}%';

    // 3. Compute Study Time & Streak
    int studySecondsToday = 0;
    int streakDays = 0;

    sessionsState.whenData((sessions) {
      final now = DateTime.now();
      
      // Calculate today's time
      for (final s in sessions) {
        if (s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day) {
          studySecondsToday += s.durationSeconds;
        }
      }
      
      // Calculate streak
      final dates = sessions.map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day)).toSet().toList();
      dates.sort((a, b) => b.compareTo(a)); // Newest first
      
      DateTime expectedDate = DateTime(now.year, now.month, now.day);
      if (dates.isNotEmpty && dates.first.isBefore(expectedDate)) {
          expectedDate = expectedDate.subtract(const Duration(days: 1)); // allow yesterday as current streak if today not studied yet
      }
      
      for (final date in dates) {
        if (date.isAtSameMomentAs(expectedDate)) {
          streakDays++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(expectedDate)) {
          break;
        }
      }
    });

    final hours = studySecondsToday ~/ 3600;
    final mins = (studySecondsToday % 3600) ~/ 60;
    final studyTimeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          const SizedBox(width: 580, child: ClockCard()),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Tasks Today', value: '$completedToday / $tasksToday', subtitle: taskProgressStr, icon: Icons.task_alt, color: Colors.green, progress: taskProgress)),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Study Time', value: studyTimeStr, subtitle: 'Today', icon: Icons.schedule, color: Colors.blue)),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Streak', value: '$streakDays days', subtitle: 'Keep it up!', icon: Icons.local_fire_department, color: Colors.orange)),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Completed', value: '$totalCompleted', subtitle: 'Total Lifetime', icon: Icons.check_box, color: Colors.teal)),
        ],
      ),
    );
  }
}

class ClockCard extends StatefulWidget {
  const ClockCard({super.key});

  @override
  State<ClockCard> createState() => _ClockCardState();
}

class _ClockCardState extends State<ClockCard> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm').format(_now);
    final amPmStr = DateFormat('a').format(_now);
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(_now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Expanded text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '"',
                    style: TextStyle(fontSize: 24, color: Colors.grey, height: 0.5),
                  ),
                  const Text(
                    'Small daily progress\nleads to big results.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('– Keep Learning 🚀', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            
            // Analog Clock placeholder (or simple circle)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
              ),
              child: const Icon(Icons.access_time, size: 40, color: Colors.white54), // Simplified analog clock
            ),
            const SizedBox(width: 24),
            
            // Digital Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      amPmStr,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Study Time Today 3h 24m',
                        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (title == 'Tasks Today' && progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
