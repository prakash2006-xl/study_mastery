import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/family_insights_provider.dart';

class UnsupportedPlatformBanner extends ConsumerWidget {
  const UnsupportedPlatformBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb && Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final platformName = kIsWeb ? 'Web Browser' : (Platform.isWindows ? 'Windows Desktop' : Platform.operatingSystem);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 10),
              Text(
                'Running on $platformName (Desktop / Demo Mode)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hardware activity collectors (UsageStatsManager, BatteryManager, NetworkStatsManager, NotificationListenerService) '
            'run natively on Android devices. On $platformName, you can view existing local database records, '
            'test JSON/CSV exports, or generate sample monitoring metrics to test all dashboards and reports.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  ref.read(familyInsightsControllerProvider.notifier).populateSampleData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample monitoring data generated successfully!')),
                  );
                },
                icon: const Icon(Icons.auto_graph_rounded, size: 18),
                label: const Text('Load Sample Data Demo'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(familyInsightsControllerProvider.notifier).clearAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All local monitoring data cleared.')),
                  );
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Clear All Data'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

