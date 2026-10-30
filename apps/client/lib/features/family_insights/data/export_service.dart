import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../core/filesystem/filesystem_service.dart';
import '../domain/models/device_activity_model.dart';
import '../domain/models/app_usage_model.dart';
import '../domain/models/screen_activity_model.dart';
import '../domain/models/notification_metadata_model.dart';
import '../domain/models/battery_model.dart';
import '../domain/models/network_usage_model.dart';
import '../domain/models/location_model.dart';
import '../domain/models/daily_activity_report_model.dart';

class FamilyInsightsExportService {
  static Future<String> exportToJson({
    required DeviceActivity? deviceActivity,
    required List<DailyActivityReport> reports,
    required List<AppUsageSummary> appSummaries,
    required List<ScreenActivity> screenActivities,
    required List<NotificationMetadata> notifications,
    required List<BatteryRecord> batteryHistory,
    required List<NetworkUsage> networkUsages,
    required List<LocationRecord> locations,
  }) async {
    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'format': 'FamilyInsights_JSON_v1',
      'device_info': deviceActivity?.toMap() ?? {},
      'daily_reports': reports.map((r) => r.toMap()).toList(),
      'app_usage_summaries': appSummaries.map((s) => s.toMap()).toList(),
      'screen_activities': screenActivities.map((s) => s.toMap()).toList(),
      'notification_metadata': notifications.map((n) => n.toMap()).toList(),
      'battery_history': batteryHistory.map((b) => b.toMap()).toList(),
      'network_usage': networkUsages.map((nu) => nu.toMap()).toList(),
      'location_history': locations.map((l) => l.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final filePath = await _saveToFile('family_insights_export_${_timestamp()}.json', jsonString);
    return filePath;
  }

  static Future<String> exportToCsv({
    required String dataType,
    required List<Map<String, dynamic>> records,
  }) async {
    if (records.isEmpty) {
      final emptyCsv = 'timestamp,status\n${DateTime.now().toIso8601String()},no_records_available';
      return await _saveToFile('family_insights_${dataType}_${_timestamp()}.csv', emptyCsv);
    }

    final headers = records.first.keys.toList();
    final buffer = StringBuffer();

    // Write header line
    buffer.writeln(headers.map(_escapeCsvField).join(','));

    // Write records
    for (final row in records) {
      final line = headers.map((key) {
        final val = row[key];
        return _escapeCsvField(val?.toString() ?? '');
      }).join(',');
      buffer.writeln(line);
    }

    final filePath = await _saveToFile('family_insights_${dataType}_${_timestamp()}.csv', buffer.toString());
    return filePath;
  }

  static String _escapeCsvField(dynamic field) {
    final text = field.toString();
    if (text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  static Future<String> _saveToFile(String fileName, String content) async {
    if (kIsWeb) {
      return fileName;
    }

    final basePath = FilesystemService.appDocDir?.path ?? Directory.systemTemp.path;
    final dirPath = p.join(basePath, 'LearningOS_Data', 'FamilyInsights_Exports');
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = p.join(dirPath, fileName);
    final file = File(filePath);
    await file.writeAsString(content);
    return filePath;
  }
}
