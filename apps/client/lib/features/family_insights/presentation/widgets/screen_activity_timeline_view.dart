import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/screen_activity_model.dart';

class ScreenActivityTimelineView extends ConsumerWidget {
  const ScreenActivityTimelineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenActivitiesAsync = ref.watch(screenActivitiesProvider);

    return screenActivitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading screen events: $e')),
      data: (activities) {
        if (activities.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.screen_lock_portrait_rounded, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'No Screen Activity Logged Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Screen lock/unlock and interactive transitions will appear here once recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          );
        }

        final interactiveCount = activities.where((a) => a.eventType == 'SCREEN_INTERACTIVE').length;
        final unlocksCount = activities.where((a) => a.eventType == 'KEYGUARD_HIDDEN').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.touch_app_rounded, color: theme.colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Screen Activations', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$interactiveCount',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock_open_rounded, color: theme.colorScheme.tertiary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Device Unlocks', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$unlocksCount',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Timeline List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Screen & Keyguard Timeline',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        final isLast = index == activities.length - 1;
                        final isInteractive = act.eventType == 'SCREEN_INTERACTIVE';
                        final isUnlock = act.eventType == 'KEYGUARD_HIDDEN';
                        final isLock = act.eventType == 'KEYGUARD_SHOWN';

                        Color eventColor = theme.colorScheme.primary;
                        IconData eventIcon = Icons.power_settings_new_rounded;

                        if (isInteractive) {
                          eventColor = Colors.teal;
                          eventIcon = Icons.screen_share_rounded;
                        } else if (isUnlock) {
                          eventColor = Colors.green;
                          eventIcon = Icons.lock_open_rounded;
                        } else if (isLock) {
                          eventColor = Colors.orange;
                          eventIcon = Icons.lock_outline_rounded;
                        } else {
                          eventColor = Colors.grey;
                          eventIcon = Icons.phone_android_rounded;
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline vertical indicator
                              Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: eventColor.withValues(alpha: 0.15),
                                      border: Border.all(color: eventColor, width: 2),
                                    ),
                                    child: Icon(eventIcon, size: 16, color: eventColor),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Colors.grey.withValues(alpha: 0.25),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act.readableTitle,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d • h:mm:ss a').format(act.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
}

