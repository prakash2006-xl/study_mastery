import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCardsRow extends StatelessWidget {
  const SummaryCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: const [
          SizedBox(width: 580, child: ClockCard()),
          SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Tasks Today', value: '5 / 8', subtitle: '62%', icon: Icons.task_alt, color: Colors.green)),
          SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Study Time', value: '3h 24m', subtitle: '+1.2h vs yesterday', icon: Icons.schedule, color: Colors.blue)),
          SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Streak', value: '12 days', subtitle: 'Keep it up!', icon: Icons.local_fire_department, color: Colors.orange)),
          SizedBox(width: 16),
          SizedBox(width: 300, child: StatsCard(title: 'Completed', value: '23', subtitle: 'Tasks', icon: Icons.check_box, color: Colors.teal)),
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

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
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
            if (title == 'Tasks Today') ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.62,
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
