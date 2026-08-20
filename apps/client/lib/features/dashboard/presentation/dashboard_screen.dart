import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Personal Learning OS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/serious_study'),
              icon: const Icon(Icons.menu_book),
              label: const Text('Serious Study Mode'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/scribble'),
              icon: const Icon(Icons.draw),
              label: const Text('Scribble Canvas'),
            ),
          ],
        ),
      ),
    );
  }
}
