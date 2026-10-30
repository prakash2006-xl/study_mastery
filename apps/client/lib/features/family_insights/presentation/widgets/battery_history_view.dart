import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/battery_model.dart';

class BatteryHistoryView extends ConsumerWidget {
  const BatteryHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final batteryHistoryAsync = ref.watch(batteryHistoryListProvider);
    final latestBatteryAsync = ref.watch(latestBatteryRecordProvider);

    return latestBatteryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading battery status: $e')),
      data: (latest) {
        final history = batteryHistoryAsync.valueOrNull ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Battery Gauge Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    // Battery Gauge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: latest != null ? (latest.batteryLevel / 100.0).clamp(0.0, 1.0) : 0.0,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getBatteryColor(latest?.batteryLevel ?? 0),
                            ),
                          ),
                        ),
                        Text(
                          latest != null && latest.batteryLevel >= 0 ? '${latest.batteryLevel}%' : '--',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                latest?.isCharging == true
                                    ? Icons.battery_charging_full_rounded
                                    : Icons.battery_full_rounded,
                                color: _getBatteryColor(latest?.batteryLevel ?? 0),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                latest?.chargingStatus ?? 'Status Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Plugged: ${latest?.pluggedType ?? "NONE"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latest != null
                                ? 'Updated: ${DateFormat('h:mm a').format(latest.timestamp)}'
                                : 'No battery snapshot yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Battery History Log
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
                          'Battery Level History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${history.length} snapshots',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No battery history logged yet.',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.take(15).length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final b = history[index];
                          final isCharging = b.chargingStatus == 'CHARGING';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getBatteryColor(b.batteryLevel).withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                isCharging ? Icons.bolt_rounded : Icons.battery_std_rounded,
                                color: _getBatteryColor(b.batteryLevel),
                                size: 20,
                              ),
                            ),
                            title: Text('${b.batteryLevel}% • ${b.chargingStatus}'),
                            subtitle: Text('Power Source: ${b.pluggedType}', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              DateFormat('MMM d • h:mm a').format(b.timestamp),
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.amber;
    return Colors.red;
  }
}

