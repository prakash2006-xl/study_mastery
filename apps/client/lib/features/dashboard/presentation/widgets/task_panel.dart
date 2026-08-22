import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/task_repository.dart';
import '../../../tasks/application/task_provider.dart';

class TaskPanel extends ConsumerStatefulWidget {
  const TaskPanel({super.key});

  @override
  ConsumerState<TaskPanel> createState() => _TaskPanelState();
}

class _TaskPanelState extends ConsumerState<TaskPanel> {
  String _activeTab = 'All';
  final TextEditingController _taskController = TextEditingController();

  final List<String> _tabs = ['All', 'Today', 'Upcoming', 'Completed'];

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (_taskController.text.trim().isNotEmpty) {
      ref.read(taskNotifierProvider.notifier).addTask(_taskController.text.trim());
      _taskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskNotifierProvider);
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
                const Text('My Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: _tabs.map((tab) {
                        final isActive = _activeTab == tab;
                        return GestureDetector(
                          onTap: () => setState(() => _activeTab = tab),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? theme.colorScheme.primary : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              tab,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Add Task Field
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(Icons.add, color: Colors.grey, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Add a new study task...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      onPressed: _addTask,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Task List
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (tasks) {
                  List<StudyTask> filteredTasks = tasks;
                  if (_activeTab == 'Completed') {
                    filteredTasks = tasks.where((t) => t.isCompleted).toList();
                  } else if (_activeTab == 'Today') {
                    final now = DateTime.now();
                    filteredTasks = tasks.where((t) {
                      if (t.isCompleted) return false;
                      final isDueToday = t.dueDate != null && t.dueDate!.year == now.year && t.dueDate!.month == now.month && t.dueDate!.day == now.day;
                      final isCreatedToday = t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day;
                      return isDueToday || (t.dueDate == null && isCreatedToday);
                    }).toList();
                  } else if (_activeTab == 'Upcoming') {
                    final now = DateTime.now();
                    filteredTasks = tasks.where((t) {
                      if (t.isCompleted) return false;
                      final isDueToday = t.dueDate != null && t.dueDate!.year == now.year && t.dueDate!.month == now.month && t.dueDate!.day == now.day;
                      final isCreatedToday = t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day;
                      return !(isDueToday || (t.dueDate == null && isCreatedToday));
                    }).toList();
                  }

                  if (filteredTasks.isEmpty) {
                    return const Center(child: Text('No tasks found.', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.separated(
                    itemCount: filteredTasks.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return TaskItemWidget(task: filteredTasks[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View all tasks', style: TextStyle(color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskItemWidget extends ConsumerWidget {
  final StudyTask task;

  const TaskItemWidget({super.key, required this.task});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool completed = task.isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: completed ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(taskNotifierProvider.notifier).toggleTaskCompletion(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: completed ? theme.colorScheme.tertiary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: completed ? theme.colorScheme.tertiary : Colors.grey,
                    width: 2,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.category,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priority,
                style: TextStyle(
                  fontSize: 10, 
                  color: completed ? Colors.grey : _getPriorityColor(task.priority), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Date / Time Placeholder
            SizedBox(
              width: 80,
              child: Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final isDueToday = task.dueDate != null && task.dueDate!.year == now.year && task.dueDate!.month == now.month && task.dueDate!.day == now.day;
                  final isCreatedToday = task.createdAt.year == now.year && task.createdAt.month == now.month && task.createdAt.day == now.day;
                  
                  String dateLabel;
                  if (task.dueDate != null) {
                    dateLabel = isDueToday ? 'Today' : DateFormat('MMM d').format(task.dueDate!);
                  } else {
                    dateLabel = isCreatedToday ? 'Today' : DateFormat('MMM d').format(task.createdAt);
                  }

                  return Text(
                    dateLabel,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
