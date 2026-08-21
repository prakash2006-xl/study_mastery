import 'package:flutter/material.dart';

class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                const Row(
                  children: [
                    Text('May 2025', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
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
                  // Mock Calendar Grid
                  _buildWeekRow(['28', '29', '30', '1', '2', '3', '4'], theme, [false, false, false, false, false, false, false]),
                  _buildWeekRow(['5', '6', '7', '8', '9', '10', '11'], theme, [false, false, false, false, false, false, false]),
                  _buildWeekRow(['12', '13', '14', '15', '16', '17', '18'], theme, [true, true, true, false, true, true, false]),
                  _buildWeekRow(['19', '20', '21', '22', '23', '24', '25'], theme, [true, true, true, true, false, false, false], todayIndex: 3),
                  _buildWeekRow(['26', '27', '28', '29', '30', '31', '1'], theme, [false, false, false, false, false, false, false]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(List<String> days, ThemeData theme, List<bool> active, {int todayIndex = -1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final isToday = todayIndex == i;
        final isActive = active[i];
        
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
            days[i],
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
