import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tasks/application/task_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskNotifierProvider);
    final sortOrder = ref.watch(taskSortOrderProvider);

    final TextEditingController taskController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Dashboard'),
        actions: [
          DropdownButton<TaskSortOrder>(
            value: sortOrder,
            icon: const Icon(Icons.sort, color: Colors.white),
            dropdownColor: Theme.of(context).colorScheme.surface,
            underline: const SizedBox(),
            onChanged: (TaskSortOrder? newValue) {
              if (newValue != null) {
                ref.read(taskSortOrderProvider.notifier).state = newValue;
              }
            },
            items: const [
              DropdownMenuItem(
                value: TaskSortOrder.uncompletedFirst,
                child: Text('Uncompleted First'),
              ),
              DropdownMenuItem(
                value: TaskSortOrder.newest,
                child: Text('Newest First'),
              ),
              DropdownMenuItem(
                value: TaskSortOrder.oldest,
                child: Text('Oldest First'),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Navigation Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TiltCard(
                    title: 'Serious Study',
                    icon: Icons.menu_book,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => context.push('/serious_study'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TiltCard(
                    title: 'Scribble Canvas',
                    icon: Icons.draw,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => context.push('/scribble'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Task Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new study task...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        ref.read(taskNotifierProvider.notifier).addTask(value.trim());
                        taskController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 32, color: Colors.deepPurpleAccent),
                  onPressed: () {
                    final value = taskController.text;
                    if (value.trim().isNotEmpty) {
                      ref.read(taskNotifierProvider.notifier).addTask(value.trim());
                      taskController.clear();
                    }
                  },
                )
              ],
            ),
          ),

          // Task List
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks yet. Create one above!'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) {
                          ref.read(taskNotifierProvider.notifier).toggleTaskCompletion(task);
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TiltCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const TiltCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _xOffset = (event.localPosition.dx - 100) / 500;
          _yOffset = (event.localPosition.dy - 50) / 500;
        });
      },
      onExit: (event) {
        setState(() {
          _xOffset = 0;
          _yOffset = 0;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 200),
          builder: (context, val, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_yOffset)
                ..rotateY(-_xOffset),
              alignment: FractionalOffset.center,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.8),
                      widget.color.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(_xOffset * 20, _yOffset * 20),
                    )
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    Icon(widget.icon, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
