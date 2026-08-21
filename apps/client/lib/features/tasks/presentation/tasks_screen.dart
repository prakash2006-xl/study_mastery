import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/task_provider.dart';
import '../../../core/database/task_repository.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _taskController = TextEditingController();
  String _activeCategory = 'All';
  
  final List<String> _categories = ['All', 'General', 'Homework', 'Reading', 'Exam Prep'];

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _showAddTaskModal(BuildContext context, WidgetRef ref) {
    String selectedCategory = 'General';
    String selectedPriority = 'Medium';

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
                  const Text('New Task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.where((c) => c != 'All').map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) => setModalState(() => selectedCategory = cat),
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['High', 'Medium', 'Low'].map((pri) {
                      final isSelected = selectedPriority == pri;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(pri),
                          selected: isSelected,
                          onSelected: (val) => setModalState(() => selectedPriority = pri),
                          selectedColor: _getPriorityColor(pri).withOpacity(0.3),
                        ),
                      );
                    }).toList(),
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
                        if (_taskController.text.trim().isNotEmpty) {
                          ref.read(taskNotifierProvider.notifier).addTask(
                            _taskController.text.trim(),
                            category: selectedCategory,
                            priority: selectedPriority,
                          );
                          _taskController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskModal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            floating: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _activeCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _activeCategory = cat),
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            sliver: tasksAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, st) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
              data: (tasks) {
                final filteredTasks = _activeCategory == 'All' 
                    ? tasks 
                    : tasks.where((t) => t.category == _activeCategory).toList();

                if (filteredTasks.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No tasks found.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(task, theme, ref);
                    },
                    childCount: filteredTasks.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(StudyTask task, ThemeData theme, WidgetRef ref) {
    final completed = task.isCompleted;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(taskNotifierProvider.notifier).toggleTaskCompletion(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: completed ? theme.colorScheme.tertiary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      color: completed ? Colors.grey : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(task.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      const SizedBox(width: 16),
                      Icon(Icons.flag_outlined, size: 14, color: _getPriorityColor(task.priority)),
                      const SizedBox(width: 4),
                      Text(task.priority, style: TextStyle(fontSize: 12, color: _getPriorityColor(task.priority))),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
              },
            )
          ],
        ),
      ),
    );
  }
}
