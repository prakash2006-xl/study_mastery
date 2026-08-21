import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../../core/database/dashboard_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _eventController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  List<ScheduleItem> _getEventsForDay(DateTime day, List<ScheduleItem> allEvents) {
    return allEvents.where((event) {
      return event.scheduledTime.year == day.year &&
             event.scheduledTime.month == day.month &&
             event.scheduledTime.day == day.day;
    }).toList();
  }

  void _showAddEventModal() {
    TimeOfDay selectedTime = TimeOfDay.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Schedule Item', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _eventController,
                    decoration: InputDecoration(
                      hintText: 'Event Title',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time'),
                    trailing: Text(selectedTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedTime);
                      if (time != null) {
                        setModalState(() => selectedTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_eventController.text.trim().isNotEmpty) {
                          final dt = DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          ref.read(scheduleItemNotifierProvider.notifier).addScheduleItem(_eventController.text.trim(), dt);
                          _eventController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Event'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleAsync = ref.watch(scheduleItemNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 28),
                  const SizedBox(width: 12),
                  const Text('Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.today),
                    tooltip: 'Today',
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = _focusedDay;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showAddEventModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Event'),
                  ),
                ],
              ),
            ),
            
            // Calendar widget
            Expanded(
              child: scheduleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (allEvents) {
                  final eventsForSelectedDay = _selectedDay != null 
                      ? _getEventsForDay(_selectedDay!, allEvents)
                      : [];

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              if (!isSameDay(_selectedDay, selectedDay)) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              }
                            },
                            onFormatChanged: (format) {
                              if (_calendarFormat != format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              }
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            eventLoader: (day) => _getEventsForDay(day, allEvents),
                            calendarStyle: CalendarStyle(
                              selectedDecoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedDay != null ? DateFormat('EEEE, MMMM d').format(_selectedDay!) : 'Events',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: eventsForSelectedDay.isEmpty
                            ? const Center(child: Text('No events for this day.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: eventsForSelectedDay.length,
                                itemBuilder: (context, index) {
                                  final event = eventsForSelectedDay[index];
                                  final timeStr = DateFormat('hh:mm a').format(event.scheduledTime);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: event.isCompleted ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(
                                        event.title,
                                        style: TextStyle(
                                          decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                                          color: event.isCompleted ? Colors.grey : Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(timeStr),
                                      trailing: IconButton(
                                        icon: Icon(
                                          event.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: event.isCompleted ? theme.colorScheme.tertiary : Colors.grey,
                                        ),
                                        onPressed: () => ref.read(scheduleItemNotifierProvider.notifier).toggleScheduleItem(event),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
