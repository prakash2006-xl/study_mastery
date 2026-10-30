import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/network_usage_model.dart';

class NetworkUsageView extends ConsumerWidget {
  const NetworkUsageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final networkAsync = ref.watch(networkUsageListProvider);

    return networkAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading network stats: $e')),
      data: (networkRecords) {
        // Calculate totals
        int totalWifiRx = 0;
        int totalWifiTx = 0;
        int totalMobileRx = 0;
        int totalMobileTx = 0;

        final appRecords = <NetworkUsage>[];

        for (final rec in networkRecords) {
          if (rec.packageName == 'ALL') {
            if (rec.networkType == 'WIFI') {
              totalWifiRx += rec.rxBytes;
              totalWifiTx += rec.txBytes;
            } else if (rec.networkType == 'MOBILE') {
              totalMobileRx += rec.rxBytes;
              totalMobileTx += rec.txBytes;
            }
          } else {
            appRecords.add(rec);
          }
        }

        final wifiTotal = totalWifiRx + totalWifiTx;
        final mobileTotal = totalMobileRx + totalMobileTx;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandwidth Cards (Wi-Fi and Mobile)
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.wifi_rounded, color: theme.colorScheme.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text('Wi-Fi Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            NetworkUsage.formatBytes(wifiTotal),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '↓ ${NetworkUsage.formatBytes(totalWifiRx)}  •  ↑ ${NetworkUsage.formatBytes(totalWifiTx)}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.signal_cellular_alt_rounded, color: theme.colorScheme.secondary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text('Mobile Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            NetworkUsage.formatBytes(mobileTotal),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '↓ ${NetworkUsage.formatBytes(totalMobileRx)}  •  ↑ ${NetworkUsage.formatBytes(totalMobileTx)}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Per-App Network Usage List
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
                          'Per-Application Data Consumption',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${appRecords.length} entries',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (appRecords.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No per-application network breakdowns available for this period.',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: appRecords.take(15).length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = appRecords[index];
                          final isWifi = item.networkType == 'WIFI';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: (isWifi ? theme.colorScheme.primary : theme.colorScheme.secondary)
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                isWifi ? Icons.wifi_rounded : Icons.cell_tower_rounded,
                                color: isWifi ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                size: 18,
                              ),
                            ),
                            title: Text(item.packageName ?? 'Application', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.networkType} • ↓ ${NetworkUsage.formatBytes(item.rxBytes)}  ↑ ${NetworkUsage.formatBytes(item.txBytes)}',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                            trailing: Text(
                              NetworkUsage.formatBytes(item.totalBytes),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

