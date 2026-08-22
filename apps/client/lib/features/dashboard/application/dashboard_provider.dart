import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/dashboard_repository.dart';

// --- App Launch Time ---
final _startupTime = DateTime.now();
final appLaunchTimeProvider = Provider<DateTime>((ref) {
  return _startupTime;
});

// --- Alarms ---
final alarmNotifierProvider = AsyncNotifierProvider<AlarmNotifier, List<Alarm>>(() {
  return AlarmNotifier();
});

class AlarmNotifier extends AsyncNotifier<List<Alarm>> {
  @override
  Future<List<Alarm>> build() async {
    final repo = await ref.read(dashboardRepositoryProvider.future);
    return repo.getAllAlarms();
  }

  Future<void> addAlarm(String label, DateTime time) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.insertAlarm(Alarm(
        id: const Uuid().v4(),
        label: label,
        time: time,
        createdAt: DateTime.now(),
      ));
      return repo.getAllAlarms();
    });
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.updateAlarm(Alarm(
        id: alarm.id,
        label: alarm.label,
        time: alarm.time,
        isEnabled: !alarm.isEnabled,
        createdAt: alarm.createdAt,
      ));
      return repo.getAllAlarms();
    });
  }

  Future<void> deleteAlarm(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.deleteAlarm(id);
      return repo.getAllAlarms();
    });
  }
}

// --- Study Sessions ---
final studySessionNotifierProvider = AsyncNotifierProvider<StudySessionNotifier, List<StudySession>>(() {
  return StudySessionNotifier();
});

class StudySessionNotifier extends AsyncNotifier<List<StudySession>> {
  @override
  Future<List<StudySession>> build() async {
    final repo = await ref.read(dashboardRepositoryProvider.future);
    return repo.getAllStudySessions();
  }

  Future<void> addStudySession(DateTime startTime, DateTime endTime, int durationSeconds) async {
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.insertStudySession(StudySession(
        id: const Uuid().v4(),
        startTime: startTime,
        endTime: endTime,
        durationSeconds: durationSeconds,
        createdAt: DateTime.now(),
      ));
      
      // Automatically log the activity
      await repo.insertActivityLog(ActivityLog(
        id: const Uuid().v4(),
        description: 'Study Session: ${(durationSeconds / 60).toStringAsFixed(0)}m',
        iconType: 'timer',
        createdAt: DateTime.now(),
      ));
      ref.invalidate(activityLogNotifierProvider);
      
      return repo.getAllStudySessions();
    });
  }
}

// --- Schedule Items ---
final scheduleItemNotifierProvider = AsyncNotifierProvider<ScheduleItemNotifier, List<ScheduleItem>>(() {
  return ScheduleItemNotifier();
});

class ScheduleItemNotifier extends AsyncNotifier<List<ScheduleItem>> {
  @override
  Future<List<ScheduleItem>> build() async {
    final repo = await ref.read(dashboardRepositoryProvider.future);
    return repo.getAllScheduleItems();
  }

  Future<void> addScheduleItem(String title, DateTime scheduledTime) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.insertScheduleItem(ScheduleItem(
        id: const Uuid().v4(),
        title: title,
        scheduledTime: scheduledTime,
        createdAt: DateTime.now(),
      ));
      ref.read(activityLogNotifierProvider.notifier).logActivity('Added schedule: $title', 'document');
      return repo.getAllScheduleItems();
    });
  }

  Future<void> toggleScheduleItem(ScheduleItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.updateScheduleItem(ScheduleItem(
        id: item.id,
        title: item.title,
        scheduledTime: item.scheduledTime,
        isCompleted: !item.isCompleted,
        createdAt: item.createdAt,
      ));
      return repo.getAllScheduleItems();
    });
  }
  Future<void> deleteScheduleItem(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.deleteScheduleItem(id);
      return repo.getAllScheduleItems();
    });
  }
}

// --- Quick Notes ---
final quickNoteNotifierProvider = AsyncNotifierProvider<QuickNoteNotifier, List<QuickNote>>(() {
  return QuickNoteNotifier();
});

class QuickNoteNotifier extends AsyncNotifier<List<QuickNote>> {
  @override
  Future<List<QuickNote>> build() async {
    final repo = await ref.read(dashboardRepositoryProvider.future);
    return repo.getRecentQuickNotes();
  }

  Future<void> addQuickNote(String title, String content) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.insertQuickNote(QuickNote(
        id: const Uuid().v4(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
      ));
      ref.read(activityLogNotifierProvider.notifier).logActivity('Added note: $title', 'document');
      return repo.getRecentQuickNotes();
    });
  }

  Future<void> deleteQuickNote(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.deleteQuickNote(id);
      return repo.getRecentQuickNotes();
    });
  }
}

// --- Activity Logs ---
final activityLogNotifierProvider = AsyncNotifierProvider<ActivityLogNotifier, List<ActivityLog>>(() {
  return ActivityLogNotifier();
});

class ActivityLogNotifier extends AsyncNotifier<List<ActivityLog>> {
  @override
  Future<List<ActivityLog>> build() async {
    final repo = await ref.read(dashboardRepositoryProvider.future);
    return repo.getRecentActivityLogs();
  }
  
  Future<void> logActivity(String description, String iconType) async {
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(dashboardRepositoryProvider.future);
      await repo.insertActivityLog(ActivityLog(
        id: const Uuid().v4(),
        description: description,
        iconType: iconType,
        createdAt: DateTime.now(),
      ));
      return repo.getRecentActivityLogs();
    });
  }
}
