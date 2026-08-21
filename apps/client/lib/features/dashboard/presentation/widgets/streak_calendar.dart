import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/dashboard_provider.dart';

class StreakCalendar extends ConsumerWidget {
  const StreakCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(studySessionNotifierProvider);
    
    final now = DateTime.now();
    final currentMonthYearStr = DateFormat('MMMM yyyy').format(now);
    
    // Calculate calendar grid for the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDayOfMonth.weekday;
    
    // Calculate days
    List<DateTime?> daysInCalendar = [];
    // Add empty days before the first day
    for (int i = 1; i < firstWeekday; i++) {
      daysInCalendar.add(null);
    }
    // Add actual days
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      daysInCalendar.add(DateTime(now.year, now.month, i));
    }
    // Add empty days after the last day to complete the week
    while (daysInCalendar.length % 7 != 0) {
      daysInCalendar.add(null);
    }
    
    // Group by weeks
    List<List<DateTime?>> weeks = [];
    for (int i = 0; i < daysInCalendar.length; i += 7) {
      weeks.add(daysInCalendar.sublist(i, i + 7));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Streak Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(currentMonthYearStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error')),
                data: (sessions) {
                  // Find all unique dates where a study session happened this month
                  Set<String> activeDates = {};
                  for (final session in sessions) {
                    if (session.startTime.year == now.year && session.startTime.month == now.month) {
                      activeDates.add(DateFormat('yyyy-MM-dd').format(session.startTime));
                    }
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('M', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('T', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('W', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('T', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('F', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('S', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('S', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      ...weeks.map((week) {
                        return _buildWeekRow(week, activeDates, now, theme);
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime?> week, Set<String> activeDates, DateTime today, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final date = week[i];
        if (date == null) {
          return const SizedBox(width: 20, height: 20);
        }
        
        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final isActive = activeDates.contains(dateStr);
        
        return Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday 
                ? theme.colorScheme.primary 
                : (isActive ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent),
            shape: BoxShape.circle,
          ),
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 10,
              color: isToday ? Colors.white : (isActive ? Colors.white : Colors.grey),
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }
}
