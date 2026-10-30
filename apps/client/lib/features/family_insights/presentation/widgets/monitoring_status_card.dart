import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import 'permissions_setup_sheet.dart';

class MonitoringStatusCard extends ConsumerWidget {
  const MonitoringStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deviceAsync = ref.watch(currentDeviceActivityProvider);
    final permissionsAsync = ref.watch(monitoringPermissionsMapProvider);
    final controllerState = ref.watch(familyInsightsControllerProvider);

    return deviceAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading status: $e'),
        ),
      ),
      data: (device) {
        final permissions = permissionsAsync.valueOrNull ?? {};
        final isPaused = permissions['monitoring_paused'] == true;
        final lastSyncText = device != null
            ? DateFormat('MMM d, y • h:mm a').format(device.lastSyncTimestamp)
            : 'Not synced yet';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPaused
                                ? Colors.orange.withValues(alpha: 0.15)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPaused
                                ? Icons.pause_circle_filled_rounded
                                : Icons.shield_rounded,
                            color: isPaused ? Colors.orange : theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device?.deviceModel ?? 'Student Device',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              device?.osVersion ?? 'Android Platform',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaused
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPaused ? Colors.orange : Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPaused ? Colors.orange : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPaused ? 'PAUSED' : 'ACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPaused ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last sync: $lastSyncText',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: ${device?.deviceId ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: controllerState.isLoading
                          ? null
                          : () => ref.read(familyInsightsControllerProvider.notifier).syncNow(),
                      icon: controllerState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync Now'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(familyInsightsControllerProvider.notifier).toggleMonitoringPause(isPaused);
                      },
                      icon: Icon(
                        isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 18,
                      ),
                      label: Text(isPaused ? 'Resume Monitoring' : 'Pause Monitoring'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => const PermissionsSetupSheet(),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Permissions Setup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

