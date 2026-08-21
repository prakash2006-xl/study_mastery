import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../tasks/application/task_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(studySessionNotifierProvider);
    final tasksAsync = ref.watch(taskNotifierProvider);
    final appLaunchTime = ref.watch(appLaunchTimeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Focus Time (Last 7 Days)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  height: 300,
                  child: sessionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                    data: (sessions) {
                      final now = DateTime.now();
                      final List<double> weeklyHours = List.filled(7, 0.0);
                      
                      for (final s in sessions) {
                        final diff = now.difference(s.startTime).inDays;
                        if (diff >= 0 && diff < 7) {
                          // index 6 is today, 5 is yesterday...
                          final index = 6 - diff;
                          weeklyHours[index] += s.durationSeconds / 3600.0;
                        }
                      }
                      
                      double maxH = weeklyHours.reduce((a, b) => a > b ? a : b);
                      if (maxH < 4) maxH = 4; // minimum scale

                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxH * 1.2,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toStringAsFixed(1)}h',
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
                                  final day = now.subtract(Duration(days: 6 - value.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(DateFormat('EEE').format(day), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (maxH / 4).ceilToDouble().clamp(1.0, double.infinity),
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('0h', style: TextStyle(fontSize: 12, color: Colors.grey));
                                  return Text('${value.toInt()}h', style: const TextStyle(fontSize: 12, color: Colors.grey));
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
                            horizontalInterval: (maxH / 4).ceilToDouble().clamp(1.0, double.infinity),
                            getDrawingHorizontalLine: (value) {
                              return FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1);
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: weeklyHours[i],
                                  color: theme.colorScheme.primary,
                                  width: 24,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      int totalSeconds = 0;
                      int streakDays = 0;
                      sessionsAsync.whenData((sessions) {
                        for (var s in sessions) totalSeconds += s.durationSeconds;
                        
                        final dates = sessions.map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day)).toSet().toList();
                        dates.sort((a, b) => b.compareTo(a));
                        final now = DateTime.now();
                        DateTime expectedDate = DateTime(now.year, now.month, now.day);
                        if (dates.isNotEmpty && dates.first.isBefore(expectedDate)) {
                            expectedDate = expectedDate.subtract(const Duration(days: 1));
                        }
                        for (final date in dates) {
                          if (date.isAtSameMomentAs(expectedDate)) {
                            streakDays++;
                            expectedDate = expectedDate.subtract(const Duration(days: 1));
                          } else if (date.isBefore(expectedDate)) {
                            break;
                          }
                        }
                      });
                      
                      final totalHours = totalSeconds ~/ 3600;
                      final totalMins = (totalSeconds % 3600) ~/ 60;
                      return _buildStatCard('Total Focus Time', '${totalHours}h ${totalMins}m', Icons.timer, Colors.purple, theme);
                    }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      int streakDays = 0;
                      sessionsAsync.whenData((sessions) {
                        final dates = sessions.map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day)).toSet().toList();
                        dates.sort((a, b) => b.compareTo(a));
                        final now = DateTime.now();
                        DateTime expectedDate = DateTime(now.year, now.month, now.day);
                        if (dates.isNotEmpty && dates.first.isBefore(expectedDate)) {
                            expectedDate = expectedDate.subtract(const Duration(days: 1));
                        }
                        for (final date in dates) {
                          if (date.isAtSameMomentAs(expectedDate)) {
                            streakDays++;
                            expectedDate = expectedDate.subtract(const Duration(days: 1));
                          } else if (date.isBefore(expectedDate)) {
                            break;
                          }
                        }
                      });
                      return _buildStatCard('Current Streak', '$streakDays days', Icons.local_fire_department, Colors.orange, theme);
                    }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      double rate = 0;
                      tasksAsync.whenData((tasks) {
                        if (tasks.isNotEmpty) {
                          final completed = tasks.where((t) => t.isCompleted).length;
                          rate = (completed / tasks.length) * 100;
                        }
                      });
                      return _buildStatCard('Completion Rate', '${rate.toInt()}%', Icons.check_circle, Colors.green, theme);
                    }
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final activeDiff = DateTime.now().difference(appLaunchTime);
                      final hours = activeDiff.inHours;
                      final mins = (activeDiff.inMinutes % 60);
                      return _buildStatCard('App Active Time', '${hours}h ${mins}m', Icons.smartphone, Colors.blue, theme);
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
