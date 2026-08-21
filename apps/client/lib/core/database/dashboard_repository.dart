import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';
import 'package:uuid/uuid.dart';

// --- Models ---

class Alarm {
  final String id;
  final String label;
  final DateTime time;
  final bool isEnabled;
  final DateTime createdAt;

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    this.isEnabled = true,
    required this.createdAt,
  });

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      label: map['label'],
      time: DateTime.fromMillisecondsSinceEpoch(map['time_milliseconds']),
      isEnabled: map['is_enabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'time_milliseconds': time.millisecondsSinceEpoch,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final DateTime createdAt;

  StudySession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.createdAt,
  });

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time']),
      durationSeconds: map['duration_seconds'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class ScheduleItem {
  final String id;
  final String title;
  final DateTime scheduledTime;
  final bool isCompleted;
  final DateTime createdAt;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'],
      title: map['title'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduled_time']),
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class QuickNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  QuickNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory QuickNote.fromMap(Map<String, dynamic> map) {
    return QuickNote(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class ActivityLog {
  final String id;
  final String description;
  final String iconType;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.description,
    required this.iconType,
    required this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      description: map['description'],
      iconType: map['icon_type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'icon_type': iconType,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

// --- Repository ---

class DashboardRepository {
  final Database _db;

  DashboardRepository(this._db);

  // Alarms
  Future<void> insertAlarm(Alarm alarm) async {
    await _db.insert('alarms', alarm.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _db.update('alarms', alarm.toMap(), where: 'id = ?', whereArgs: [alarm.id]);
  }

  Future<void> deleteAlarm(String id) async {
    await _db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Alarm>> getAllAlarms() async {
    final maps = await _db.query('alarms', orderBy: 'time_milliseconds ASC');
    return maps.map((m) => Alarm.fromMap(m)).toList();
  }

  // Study Sessions
  Future<void> insertStudySession(StudySession session) async {
    await _db.insert('study_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StudySession>> getAllStudySessions() async {
    final maps = await _db.query('study_sessions', orderBy: 'start_time DESC');
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  // Schedule Items
  Future<void> insertScheduleItem(ScheduleItem item) async {
    await _db.insert('schedule_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateScheduleItem(ScheduleItem item) async {
    await _db.update('schedule_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteScheduleItem(String id) async {
    await _db.delete('schedule_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ScheduleItem>> getTodayScheduleItems() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    
    final maps = await _db.query(
      'schedule_items',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'scheduled_time ASC'
    );
    return maps.map((m) => ScheduleItem.fromMap(m)).toList();
  }

  // Quick Notes
  Future<void> insertQuickNote(QuickNote note) async {
    await _db.insert('quick_notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateQuickNote(QuickNote note) async {
    await _db.update('quick_notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteQuickNote(String id) async {
    await _db.delete('quick_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuickNote>> getRecentQuickNotes({int limit = 5}) async {
    final maps = await _db.query('quick_notes', orderBy: 'created_at DESC', limit: limit);
    return maps.map((m) => QuickNote.fromMap(m)).toList();
  }

  // Activity Logs
  Future<void> insertActivityLog(ActivityLog log) async {
    await _db.insert('activity_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ActivityLog>> getRecentActivityLogs({int limit = 10}) async {
    final maps = await _db.query('activity_logs', orderBy: 'created_at DESC', limit: limit);
    return maps.map((m) => ActivityLog.fromMap(m)).toList();
  }
}

final dashboardRepositoryProvider = FutureProvider<DashboardRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DashboardRepository(db);
});
