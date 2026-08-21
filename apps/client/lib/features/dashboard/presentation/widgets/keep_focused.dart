import 'package:flutter/material.dart';

class KeepFocusedWidget extends StatelessWidget {
  const KeepFocusedWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Row(
                  children: [
                    Icon(Icons.music_note, size: 20, color: Colors.purpleAccent),
                    SizedBox(width: 8),
                    Text('Keep Focused', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.speaker, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Lo-Fi Beats', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lo-Fi Study • Deep Focus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('24/7 Radio', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: List.generate(15, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 2,
                      height: (index % 5 + 1) * 4.0, // simple static waveform
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.volume_up, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
