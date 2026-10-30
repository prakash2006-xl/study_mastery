import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/family_insights_provider.dart';

class PermissionsSetupSheet extends ConsumerWidget {
  const PermissionsSetupSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionsAsync = ref.watch(monitoringPermissionsMapProvider);
    final service = ref.watch(familyInsightsServiceProvider);
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: permissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading permissions: $e')),
        data: (perms) {
          final usageGranted = perms['usage_stats'] == true;
          final notifGranted = perms['notification_listener'] == true;
          final locationGranted = perms['location'] == true;
          final locationEnabled = perms['location_enabled'] == true;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monitoring Permissions & Privacy',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Family Insights requires explicit device permissions to monitor student learning activity transparently on-device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Usage Stats Permission
                _PermissionTile(
                  icon: Icons.timer_outlined,
                  title: 'Usage Access (Apps & Screen)',
                  description: 'Required to measure application screen time, foreground events, and device unlock count.',
                  isGranted: usageGranted,
                  actionLabel: usageGranted ? 'Granted' : 'Grant Permission',
                  onAction: isAndroid && service != null
                      ? () => service.openPermissionSettings('usage_stats')
                      : null,
                ),

                const SizedBox(height: 12),

                // 2. Notification Listener Permission
                _PermissionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Metadata (Optional)',
                  description: 'Collects app names, timestamps, and categories (e.g. social, email). Strict zero-content policy.',
                  isGranted: notifGranted,
                  isOptional: true,
                  actionLabel: notifGranted ? 'Granted' : 'Enable Access',
                  onAction: isAndroid && service != null
                      ? () => service.openPermissionSettings('notification_listener')
                      : null,
                ),

                const SizedBox(height: 12),

                // 3. Location Permission & Opt-In
                _PermissionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Optional Device Location',
                  description: 'Disabled by default. Explicit opt-in only. Provides visible device location tracking for family safety.',
                  isGranted: locationGranted && locationEnabled,
                  isOptional: true,
                  trailing: Switch(
                    value: locationEnabled,
                    onChanged: (val) {
                      ref.read(familyInsightsControllerProvider.notifier).toggleLocationMonitoring(val);
                      if (val && !locationGranted && service != null && isAndroid) {
                        service.requestLocationPermission();
                      }
                    },
                  ),
                  actionLabel: locationGranted ? 'Permission OK' : 'Grant Location',
                  onAction: isAndroid && service != null
                      ? () => service.requestLocationPermission()
                      : null,
                ),

                const SizedBox(height: 12),

                // 4. Battery & Network Status
                _PermissionTile(
                  icon: Icons.battery_charging_full_rounded,
                  title: 'Battery & Power Status',
                  description: 'Monitors battery percentages, charging states, and device power events without special permissions.',
                  isGranted: true,
                  actionLabel: 'Active',
                ),

                const SizedBox(height: 12),

                _PermissionTile(
                  icon: Icons.network_check_rounded,
                  title: 'Network Bandwidth Usage',
                  description: 'Measures Wi-Fi and mobile data bandwidth consumed across learning applications.',
                  isGranted: true,
                  actionLabel: 'Active',
                ),

                const SizedBox(height: 24),

                // WorkManager Background Schedule Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.orange, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Background Sync (WorkManager)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Runs periodically (every 15 min) with battery restrictions. No continuous foreground drains.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: isAndroid && service != null
                            ? () {
                                service.scheduleBackgroundSync(intervalMinutes: 15);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('WorkManager periodic collection scheduled.')),
                                );
                              }
                            : null,
                        child: const Text('Schedule'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isOptional;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    this.isOptional = false,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isGranted ? Colors.green : Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    if (isOptional) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Optional', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isGranted ? 'GRANTED' : 'DISABLED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (onAction != null && !isGranted) ...[
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Configure'),
            ),
          ],
        ],
      ),
    );
  }
}

