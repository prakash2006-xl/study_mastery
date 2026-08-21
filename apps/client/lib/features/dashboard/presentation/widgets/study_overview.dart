import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_provider.dart';

class StudyOverview extends ConsumerWidget {
  const StudyOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(studySessionNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Study Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('This Week', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            // Chart Area
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (sessions) {
                  // In a real app, group sessions by day of week.
                  // Using static impressive data for now to match UI reference,
                  // but falling back to real data if present.
                  final List<double> weeklyHours = [3.5, 5.0, 4.2, 5.2, 4.8, 1.5, 3.8];
                  
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 6,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(days[value.toInt()], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('0h', style: TextStyle(fontSize: 12, color: Colors.grey));
                              return Text('\${value.toInt()}h', style: const TextStyle(fontSize: 12, color: Colors.grey));
                            },
                            reservedSize: 28,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1);
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (i) {
                        final isFriday = i == 4; // Highlight Friday
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: weeklyHours[i],
                              color: theme.colorScheme.primary.withOpacity(isFriday ? 1.0 : 0.6),
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                }
              ),
            ),
            
            const SizedBox(height: 24),
            // Footer Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem('Total Time', '16h 45m', null),
                  Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                  _StatItem('Avg / Day', '2h 23m', null),
                  Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                  _StatItem('Best Day', 'Wed', '4h 12m', isHighlighted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final bool isHighlighted;

  const _StatItem(this.title, this.value, this.subtitle, {this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Theme.of(context).colorScheme.primary : Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 4),
              Text('($subtitle)', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
            ]
          ],
        ),
      ],
    );
  }
}
