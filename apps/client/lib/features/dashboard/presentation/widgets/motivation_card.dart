import 'package:flutter/material.dart';

class MotivationCard extends StatelessWidget {
  const MotivationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quotes = [
      '"The expert in anything was once a beginner. Keep showing up."',
      '"Don\'t watch the clock; do what it does. Keep going."',
      '"The future depends on what you do today."',
      '"Success is the sum of small efforts, repeated day-in and day-out."',
      '"It always seems impossible until it is done."',
      '"The secret of getting ahead is getting started."',
    ];
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final quote = quotes[dayOfYear % quotes.length];

    return Card(
      child: Stack(
        children: [
          // Background graphic/gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.landscape,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Motivation Corner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  quote,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 20, height: 1, color: Colors.white54),
                    const SizedBox(width: 8),
                    const Text('You got this! 🚀', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
