import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/daily_activity_report_model.dart';
import '../../domain/models/network_usage_model.dart';

class DailyWeeklyReportsView extends ConsumerWidget {
  const DailyWeeklyReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportsAsync = ref.watch(dailyActivityReportsListProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading reports: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.assessment_outlined, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'No Activity Reports Generated Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daily and weekly activity reports aggregate screen time, top learning apps, and notifications. Tap "Sync Now" to generate today\'s report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          );
        }

        // 7-day trend data
        final recentReports = reports.take(7).toList().reversed.toList();
        final todayReport = reports.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Aggregate Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Report for ${todayReport.date}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Latest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MetricBox(
                          icon: Icons.timer_outlined,
                          title: 'Screen Time',
                          value: todayReport.formattedScreenTime,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _MetricBox(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          value: '${todayReport.totalNotificationsCount}',
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        _MetricBox(
                          icon: Icons.data_usage_rounded,
                          title: 'Total Network',
                          value: NetworkUsage.formatBytes(todayReport.totalWifiBytes + todayReport.totalMobileBytes),
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 7-Day Trend Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '7-Day Screen Time Trend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 8.0,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final r = recentReports[groupIndex];
                                return BarTooltipItem(
                                  '${r.date}\n${r.formattedScreenTime}',
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
                                  if (idx < 0 || idx >= recentReports.length) return const SizedBox.shrink();
                                  final d = recentReports[idx].date;
                                  // extract MM-DD
                                  final parts = d.split('-');
                                  final label = parts.length >= 3 ? '${parts[1]}/${parts[2]}' : d;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 2,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('0h', style: TextStyle(fontSize: 10, color: Colors.grey));
                                  return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white.withValues(alpha: 0.05),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(recentReports.length, (index) {
                            final r = recentReports[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: r.screenTimeHours,
                                  color: theme.colorScheme.primary,
                                  width: 18,
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

            // Daily Reports History List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historical Daily Reports',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = reports[index];
                        final totalNet = NetworkUsage.formatBytes(r.totalWifiBytes + r.totalMobileBytes);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            ),
                            child: Icon(Icons.event_note_rounded, color: theme.colorScheme.primary, size: 20),
                          ),
                          title: Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Notifications: ${r.totalNotificationsCount} • Network: $totalNet',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                r.formattedScreenTime,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text('Screen Time', style: TextStyle(fontSize: 10, color: Colors.grey)),
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

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }
}

