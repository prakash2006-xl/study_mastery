import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/notification_metadata_model.dart';

class NotificationMetadataView extends ConsumerWidget {
  const NotificationMetadataView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationMetadataListProvider);
    final categoryCountsAsync = ref.watch(notificationCategoryCountsProvider);
    final permissionsAsync = ref.watch(monitoringPermissionsMapProvider);

    final perms = permissionsAsync.valueOrNull ?? {};
    final notifGranted = perms['notification_listener'] == true;

    return notificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading notifications: $e')),
      data: (notifications) {
        final categoryCounts = categoryCountsAsync.valueOrNull ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Shield Reminder Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privacy Protection Active: Notification titles, bodies, messages, and sender information are completely stripped and never recorded.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade200),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Permission status if disabled
            if (!notifGranted && notifications.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_off_outlined, size: 44, color: Colors.orange),
                      const SizedBox(height: 12),
                      const Text(
                        'Notification Access Disabled (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Notification Access is optional. If enabled, it provides category statistics (e.g. alerts, emails, social).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          final service = ref.read(familyInsightsServiceProvider);
                          service?.openPermissionSettings('notification_listener');
                        },
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Configure Notification Access'),
                      ),
                    ],
                  ),
                ),
              ),

            // Category Counts Card
            if (categoryCounts.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notification Categories Breakdown',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: categoryCounts.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(entry.key), size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _formatCategoryName(entry.key),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recent Notification Metadata Events List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Notification Events',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${notifications.length} logged',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No notification metadata received yet.',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notifications.take(20).length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              child: Icon(_getCategoryIcon(notif.category), color: theme.colorScheme.primary, size: 18),
                            ),
                            title: Text(notif.appName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'Category: ${_formatCategoryName(notif.category)} • ${notif.packageName}',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            trailing: Text(
                              DateFormat('MMM d, h:mm a').format(notif.timestamp),
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'msg':
      case 'social':
        return Icons.chat_bubble_outline_rounded;
      case 'email':
        return Icons.mail_outline_rounded;
      case 'call':
        return Icons.call_outlined;
      case 'alarm':
      case 'reminder':
      case 'event':
        return Icons.alarm_rounded;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatCategoryName(String cat) {
    if (cat.isEmpty) return 'General';
    return cat[0].toUpperCase() + cat.substring(1);
  }
}

