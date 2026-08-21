import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/task_repository.dart';

enum TaskSortOrder { newest, oldest, uncompletedFirst }

final taskSortOrderProvider = StateProvider<TaskSortOrder>((ref) => TaskSortOrder.uncompletedFirst);

final taskNotifierProvider = AsyncNotifierProvider<TaskNotifier, List<StudyTask>>(() {
  return TaskNotifier();
});

class TaskNotifier extends AsyncNotifier<List<StudyTask>> {
  @override
  Future<List<StudyTask>> build() async {
    return _fetchAndSortTasks();
  }

  Future<List<StudyTask>> _fetchAndSortTasks() async {
    final repo = await ref.read(taskRepositoryProvider.future);
    final tasks = await repo.getAllTasks();
    final sortOrder = ref.watch(taskSortOrderProvider);

    tasks.sort((a, b) {
      if (sortOrder == TaskSortOrder.uncompletedFirst) {
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        // If same completion status, sort by newest
        return b.createdAt.compareTo(a.createdAt);
      } else if (sortOrder == TaskSortOrder.newest) {
        return b.createdAt.compareTo(a.createdAt);
      } else { // oldest
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return tasks;
  }

  Future<void> addTask(String title) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(taskRepositoryProvider.future);
      final newTask = StudyTask(
        id: const Uuid().v4(),
        title: title,
        createdAt: DateTime.now(),
      );
      await repo.insertTask(newTask);
      return _fetchAndSortTasks();
    });
  }

  Future<void> toggleTaskCompletion(StudyTask task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(taskRepositoryProvider.future);
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await repo.updateTask(updatedTask);
      return _fetchAndSortTasks();
    });
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(taskRepositoryProvider.future);
      await repo.deleteTask(id);
      return _fetchAndSortTasks();
    });
  }
}
