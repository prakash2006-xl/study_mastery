import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/app_usage_model.dart';

class AppUsageDashboardView extends ConsumerWidget {
  const AppUsageDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summariesAsync = ref.watch(appUsageSummariesProvider);
    final permissionsAsync = ref.watch(monitoringPermissionsMapProvider);

    return summariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading app usage: $e')),
      data: (summaries) {
        final perms = permissionsAsync.valueOrNull ?? {};
        final isUsageGranted = perms['usage_stats'] == true;

        if (!isUsageGranted && summaries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Usage Access Permission Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Grant Usage Access in Android Settings to collect foreground application usage and screen time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      final service = ref.read(familyInsightsServiceProvider);
                      service?.openPermissionSettings('usage_stats');
                    },
                    icon: const Icon(Icons.settings_suggest_rounded),
                    label: const Text('Open Usage Settings'),
                  ),
                ],
              ),
            ),
          );
        }

        if (summaries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'No Application Usage Collected Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Sync Now" to collect current usage stats or load sample demo data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          );
        }

        final totalDurationMs = summaries.fold<int>(0, (sum, item) => sum + item.totalDurationMs);
        final totalMinutes = (totalDurationMs / (1000 * 60)).round();
        final totalHours = totalMinutes ~/ 60;
        final remMinutes = totalMinutes % 60;
        final totalFormatted = totalHours > 0 ? '${totalHours}h ${remMinutes}m' : '${remMinutes}m';

        // Top 5 apps for chart
        final topApps = summaries.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Time Summary Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.hourglass_bottom_rounded, color: theme.colorScheme.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Screen Time',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalFormatted,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${summaries.length} apps tracked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Visual Chart of Top Apps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Applications by Usage',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (topApps.first.durationMinutes * 1.25).clamp(10.0, double.infinity),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final app = topApps[groupIndex];
                                return BarTooltipItem(
                                  '${app.appName}\n${app.formattedDuration}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= topApps.length) return const SizedBox.shrink();
                                  final name = topApps[idx].appName;
                                  final shortName = name.length > 8 ? '${name.substring(0, 7)}…' : name;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      shortName,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 38,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('0m', style: TextStyle(fontSize: 10, color: Colors.grey));
                                  return Text('${value.toInt()}m', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(topApps.length, (index) {
                            final app = topApps[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: app.durationMinutes,
                                  color: _getBarColor(index, theme),
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Detailed App Usage List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Application Metrics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summaries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = summaries[index];
                        final pct = totalDurationMs > 0
                            ? (item.totalDurationMs / totalDurationMs * 100).toStringAsFixed(1)
                            : '0.0';

                        final lastUsedStr = item.lastUsedTimestamp != null
                            ? 'Last: ${DateFormat('h:mm a').format(item.lastUsedTimestamp!)}'
                            : '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: _getBarColor(index, theme).withValues(alpha: 0.2),
                            child: Icon(
                              _getAppIcon(item.appName),
                              color: _getBarColor(index, theme),
                              size: 20,
                            ),
                          ),
                          title: Text(item.appName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${item.packageName} • $lastUsedStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.formattedDuration,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
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

  Color _getBarColor(int index, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.indigoAccent,
      Colors.pinkAccent,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  IconData _getAppIcon(String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('learn') || lower.contains('plos')) return Icons.school_rounded;
    if (lower.contains('doc') || lower.contains('read')) return Icons.description_rounded;
    if (lower.contains('tube') || lower.contains('video')) return Icons.play_circle_filled_rounded;
    if (lower.contains('music') || lower.contains('audio')) return Icons.headphones_rounded;
    if (lower.contains('khan') || lower.contains('duo')) return Icons.auto_stories_rounded;
    return Icons.apps_rounded;
  }
}

