import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/database/family_insights_repository.dart';
import '../data/family_insights_platform_channel.dart';
import '../data/export_service.dart';
import '../domain/models/device_activity_model.dart';
import '../domain/models/app_usage_model.dart';
import '../domain/models/screen_activity_model.dart';
import '../domain/models/notification_metadata_model.dart';
import '../domain/models/battery_model.dart';
import '../domain/models/network_usage_model.dart';
import '../domain/models/location_model.dart';
import '../domain/models/daily_activity_report_model.dart';

class FamilyInsightsService {
  final FamilyInsightsRepository _repository;
  final FamilyInsightsPlatformChannel _platformChannel;
  final Uuid _uuid = const Uuid();

  FamilyInsightsService({
    required FamilyInsightsRepository repository,
    FamilyInsightsPlatformChannel? platformChannel,
  })  : _repository = repository,
        _platformChannel = platformChannel ?? FamilyInsightsPlatformChannel();

  bool get isPlatformSupported => _platformChannel.isPlatformSupported;

  Future<Map<String, dynamic>> checkPermissions() async {
    final status = await _platformChannel.getPermissionsStatus();
    for (final entry in status.entries) {
      if (entry.value is bool) {
        await _repository.updatePermission(entry.key, entry.value as bool);
      }
    }
    return status;
  }

  Future<void> openPermissionSettings(String type) async {
    await _platformChannel.openPermissionSettings(type);
  }

  Future<void> requestLocationPermission() async {
    await _platformChannel.requestLocationPermission();
  }

  Future<void> setLocationMonitoringEnabled(bool enabled) async {
    await _platformChannel.setLocationMonitoringEnabled(enabled);
    await _repository.updatePermission('location_enabled', enabled);
  }

  Future<void> setMonitoringPaused(bool paused) async {
    await _platformChannel.setMonitoringPaused(paused);
    await _repository.updatePermission('monitoring_paused', paused);

    final devices = await _repository.getAllDevices();
    if (devices.isNotEmpty) {
      final current = devices.first;
      await _repository.saveDeviceActivity(
        current.copyWith(isMonitoringActive: !paused),
      );
    }
  }

  Future<void> scheduleBackgroundSync({int intervalMinutes = 15}) async {
    await _platformChannel.scheduleBackgroundWork(intervalMinutes: intervalMinutes);
  }

  Future<void> cancelBackgroundSync() async {
    await _platformChannel.cancelBackgroundWork();
  }

  Future<void> syncNow() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 1. Device Info
    final deviceInfo = await _platformChannel.getDeviceInfo();
    final deviceId = deviceInfo['device_id'] ?? 'device_default';
    final deviceActivity = DeviceActivity(
      id: deviceId,
      deviceId: deviceId,
      deviceModel: deviceInfo['device_model'] ?? 'Device',
      osVersion: deviceInfo['os_version'] ?? 'Android',
      lastSyncTimestamp: now,
      isMonitoringActive: true,
    );
    await _repository.saveDeviceActivity(deviceActivity);

    // 2. Permissions status
    await checkPermissions();

    if (!_platformChannel.isPlatformSupported) {
      return;
    }

    // 3. App Usage & Screen Activity (from start of day to now)
    final usageData = await _platformChannel.collectAppUsage(
      startTime: todayStart,
      endTime: now,
    );

    if (usageData != null) {
      final appEventsList = (usageData['app_events'] as List?) ?? [];
      final parsedAppEvents = <AppUsageEvent>[];
      for (final e in appEventsList) {
        if (e is Map) {
          final pkg = e['package_name']?.toString() ?? '';
          final ts = (e['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
          final evtType = e['event_type']?.toString() ?? 'MOVE_TO_FOREGROUND';
          parsedAppEvents.add(
            AppUsageEvent(
              id: '${deviceId}_${pkg}_${ts}_$evtType',
              deviceId: deviceId,
              packageName: pkg,
              appName: e['app_name']?.toString() ?? pkg,
              eventType: evtType,
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
            ),
          );
        }
      }
      await _repository.saveAppUsageEvents(parsedAppEvents);

      // App summaries (duration and last used)
      final summariesList = (usageData['app_summaries'] as List?) ?? [];
      final summaryEvents = <AppUsageEvent>[];
      for (final s in summariesList) {
        if (s is Map) {
          final pkg = s['package_name']?.toString() ?? '';
          final dur = (s['duration_ms'] as num?)?.toInt() ?? 0;
          final lastUsed = (s['last_used_timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
          summaryEvents.add(
            AppUsageEvent(
              id: '${deviceId}_${pkg}_summary_${todayStart.millisecondsSinceEpoch}',
              deviceId: deviceId,
              packageName: pkg,
              appName: s['app_name']?.toString() ?? pkg,
              eventType: 'DAILY_SUMMARY',
              timestamp: DateTime.fromMillisecondsSinceEpoch(lastUsed),
              durationMs: dur,
            ),
          );
        }
      }
      await _repository.saveAppUsageEvents(summaryEvents);

      // Screen events
      final screenEventsList = (usageData['screen_events'] as List?) ?? [];
      final parsedScreenEvents = <ScreenActivity>[];
      for (final se in screenEventsList) {
        if (se is Map) {
          final ts = (se['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
          final evtType = se['event_type']?.toString() ?? 'SCREEN_INTERACTIVE';
          parsedScreenEvents.add(
            ScreenActivity(
              id: '${deviceId}_screen_${ts}_$evtType',
              deviceId: deviceId,
              eventType: evtType,
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
            ),
          );
        }
      }
      await _repository.saveScreenActivities(parsedScreenEvents);
    }

    // 4. Battery Status
    final batteryData = await _platformChannel.collectBatteryStatus();
    if (batteryData != null) {
      final ts = (batteryData['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
      final batteryRecord = BatteryRecord(
        id: '${deviceId}_battery_$ts',
        deviceId: deviceId,
        batteryLevel: (batteryData['battery_level'] as num?)?.toInt() ?? 0,
        chargingStatus: batteryData['charging_status']?.toString() ?? 'UNKNOWN',
        pluggedType: batteryData['plugged_type']?.toString() ?? 'NONE',
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      );
      await _repository.saveBatteryRecords([batteryRecord]);
    }

    // 5. Network Stats
    final networkData = await _platformChannel.collectNetworkStats(
      startTime: todayStart,
      endTime: now,
    );
    if (networkData != null) {
      final ts = (networkData['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
      final wifiRx = (networkData['wifi_rx'] as num?)?.toInt() ?? 0;
      final wifiTx = (networkData['wifi_tx'] as num?)?.toInt() ?? 0;
      final mobileRx = (networkData['mobile_rx'] as num?)?.toInt() ?? 0;
      final mobileTx = (networkData['mobile_tx'] as num?)?.toInt() ?? 0;

      final networkUsages = <NetworkUsage>[
        NetworkUsage(
          id: '${deviceId}_wifi_${todayStart.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}',
          deviceId: deviceId,
          networkType: 'WIFI',
          packageName: 'ALL',
          rxBytes: wifiRx,
          txBytes: wifiTx,
          startTime: todayStart,
          endTime: now,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
        ),
        NetworkUsage(
          id: '${deviceId}_mobile_${todayStart.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}',
          deviceId: deviceId,
          networkType: 'MOBILE',
          packageName: 'ALL',
          rxBytes: mobileRx,
          txBytes: mobileTx,
          startTime: todayStart,
          endTime: now,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
        ),
      ];

      // Add per-app breakdown if present
      final appBreakdown = (networkData['app_breakdown'] as List?) ?? [];
      for (final ab in appBreakdown) {
        if (ab is Map) {
          final pkg = ab['package_name']?.toString() ?? 'app';
          final netType = ab['network_type']?.toString() ?? 'WIFI';
          final rx = (ab['rx_bytes'] as num?)?.toInt() ?? 0;
          final tx = (ab['tx_bytes'] as num?)?.toInt() ?? 0;
          networkUsages.add(
            NetworkUsage(
              id: '${deviceId}_${pkg}_${netType}_${todayStart.millisecondsSinceEpoch}',
              deviceId: deviceId,
              networkType: netType,
              packageName: pkg,
              rxBytes: rx,
              txBytes: tx,
              startTime: todayStart,
              endTime: now,
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
            ),
          );
        }
      }

      await _repository.saveNetworkUsages(networkUsages);
    }

    // 6. Notification Metadata Queue
    final notificationsList = await _platformChannel.getNotificationEvents();
    if (notificationsList.isNotEmpty) {
      final parsedNotifications = <NotificationMetadata>[];
      for (final n in notificationsList) {
        final pkg = n['package_name']?.toString() ?? '';
        final cat = n['category']?.toString() ?? 'general';
        final ts = (n['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
        parsedNotifications.add(
          NotificationMetadata(
            id: '${deviceId}_notif_${pkg}_$ts',
            deviceId: deviceId,
            packageName: pkg,
            appName: pkg.split('.').last,
            category: cat,
            timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
          ),
        );
      }
      await _repository.saveNotificationMetadata(parsedNotifications);
    }

    // 7. Optional Location
    final locationData = await _platformChannel.collectLocation();
    if (locationData != null) {
      final ts = (locationData['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
      final locRecord = LocationRecord(
        id: '${deviceId}_loc_$ts',
        deviceId: deviceId,
        latitude: (locationData['latitude'] as num).toDouble(),
        longitude: (locationData['longitude'] as num).toDouble(),
        accuracy: (locationData['accuracy'] as num?)?.toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      );
      await _repository.saveLocationRecords([locRecord]);
    }

    // 8. Pending background events from WorkManager
    final bgEvents = await _platformChannel.getPendingBackgroundEvents();
    for (final bg in bgEvents) {
      final evtType = bg['event_type']?.toString();
      final data = bg['data'];
      if (data is Map) {
        if (evtType == 'battery') {
          final ts = (data['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch;
          await _repository.saveBatteryRecords([
            BatteryRecord(
              id: '${deviceId}_bg_battery_$ts',
              deviceId: deviceId,
              batteryLevel: (data['battery_level'] as num?)?.toInt() ?? 0,
              chargingStatus: data['charging_status']?.toString() ?? 'UNKNOWN',
              pluggedType: data['plugged_type']?.toString() ?? 'NONE',
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
            )
          ]);
        }
      }
    }

    // 9. Recompute today's Daily Activity Report
    await _recalculateDailyReport(deviceId, now);
  }

  Future<void> _recalculateDailyReport(String deviceId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // Get app summaries
    final summaries = await _repository.getAppUsageSummaries(
      deviceId: deviceId,
      from: startOfDay,
      to: endOfDay,
    );

    int totalScreenSeconds = 0;
    final topApps = <String, int>{};
    for (final s in summaries) {
      final sec = (s.totalDurationMs / 1000).round();
      totalScreenSeconds += sec;
      topApps[s.appName] = s.totalDurationMs;
    }

    // Notification count
    final notifs = await _repository.getNotificationMetadata(
      deviceId: deviceId,
      from: startOfDay,
      to: endOfDay,
    );

    // Network totals
    final networkItems = await _repository.getNetworkUsage(
      deviceId: deviceId,
      from: startOfDay,
      to: endOfDay,
    );

    int wifiTotal = 0;
    int mobileTotal = 0;
    for (final item in networkItems) {
      if (item.packageName == 'ALL') {
        if (item.networkType == 'WIFI') {
          wifiTotal += item.totalBytes;
        } else if (item.networkType == 'MOBILE') {
          mobileTotal += item.totalBytes;
        }
      }
    }

    final report = DailyActivityReport(
      id: '${deviceId}_report_$dateKey',
      deviceId: deviceId,
      date: dateKey,
      totalScreenTimeSeconds: totalScreenSeconds,
      totalNotificationsCount: notifs.length,
      totalWifiBytes: wifiTotal,
      totalMobileBytes: mobileTotal,
      topApps: topApps,
      generatedAt: DateTime.now(),
    );

    await _repository.saveDailyReport(report);
  }

  Future<void> clearAllData() async {
    await _repository.clearAllData();
  }

  Future<String> exportDataAsJson() async {
    final devices = await _repository.getAllDevices();
    final device = devices.isNotEmpty ? devices.first : null;
    final deviceId = device?.deviceId;

    final reports = await _repository.getDailyReports(deviceId: deviceId);
    final summaries = await _repository.getAppUsageSummaries(deviceId: deviceId);
    final screenActs = await _repository.getScreenActivities(deviceId: deviceId);
    final notifs = await _repository.getNotificationMetadata(deviceId: deviceId);
    final battery = await _repository.getBatteryHistory(deviceId: deviceId);
    final network = await _repository.getNetworkUsage(deviceId: deviceId);
    final locations = await _repository.getLocationHistory(deviceId: deviceId);

    return await FamilyInsightsExportService.exportToJson(
      deviceActivity: device,
      reports: reports,
      appSummaries: summaries,
      screenActivities: screenActs,
      notifications: notifs,
      batteryHistory: battery,
      networkUsages: network,
      locations: locations,
    );
  }

  Future<String> exportDataAsCsv(String dataType) async {
    final devices = await _repository.getAllDevices();
    final deviceId = devices.isNotEmpty ? devices.first.deviceId : null;

    final records = <Map<String, dynamic>>[];

    switch (dataType.toLowerCase()) {
      case 'app_usage':
        final summaries = await _repository.getAppUsageSummaries(deviceId: deviceId);
        records.addAll(summaries.map((s) => s.toMap()));
        break;
      case 'battery':
        final battery = await _repository.getBatteryHistory(deviceId: deviceId);
        records.addAll(battery.map((b) => b.toMap()));
        break;
      case 'screen':
        final screen = await _repository.getScreenActivities(deviceId: deviceId);
        records.addAll(screen.map((s) => s.toMap()));
        break;
      case 'notifications':
        final notifs = await _repository.getNotificationMetadata(deviceId: deviceId);
        records.addAll(notifs.map((n) => n.toMap()));
        break;
      case 'network':
        final net = await _repository.getNetworkUsage(deviceId: deviceId);
        records.addAll(net.map((n) => n.toMap()));
        break;
      case 'daily_reports':
      default:
        final reports = await _repository.getDailyReports(deviceId: deviceId);
        records.addAll(reports.map((r) => r.toMap()));
        break;
    }

    return await FamilyInsightsExportService.exportToCsv(
      dataType: dataType,
      records: records,
    );
  }

  /// Generates realistic sample data for desktop evaluation (e.g. Windows)
  /// or demonstration purposes.
  Future<void> populateSampleData() async {
    const deviceId = 'demo_student_device';
    final now = DateTime.now();

    // 1. Device Info
    await _repository.saveDeviceActivity(
      DeviceActivity(
        id: deviceId,
        deviceId: deviceId,
        deviceModel: 'Pixel 8 Pro (Study Device)',
        osVersion: 'Android 14 (API 34)',
        lastSyncTimestamp: now,
        isMonitoringActive: true,
      ),
    );

    // 2. Monitoring Permissions
    await _repository.updatePermission('usage_stats', true);
    await _repository.updatePermission('notification_listener', true);
    await _repository.updatePermission('battery', true);
    await _repository.updatePermission('network_stats', true);
    await _repository.updatePermission('location', true);
    await _repository.updatePermission('location_enabled', true);

    // 3. App Usage Events & Summaries for past 3 days
    final sampleApps = [
      {'pkg': 'com.google.android.apps.docs.editors.docs', 'name': 'Google Docs', 'minutes': 85},
      {'pkg': 'com.duolingo', 'name': 'Duolingo', 'minutes': 45},
      {'pkg': 'org.khanacademy.android', 'name': 'Khan Academy', 'minutes': 60},
      {'pkg': 'com.example.personal_learning_os_client', 'name': 'Personal Learning OS', 'minutes': 120},
      {'pkg': 'com.google.android.youtube', 'name': 'YouTube (Educational)', 'minutes': 50},
      {'pkg': 'com.spotify.music', 'name': 'Spotify Focus Audio', 'minutes': 40},
    ];

    final appEvents = <AppUsageEvent>[];
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = now.subtract(Duration(days: dayOffset));
      final dateStart = DateTime(date.year, date.month, date.day, 8);

      for (int i = 0; i < sampleApps.length; i++) {
        final app = sampleApps[i];
        final durMs = ((app['minutes'] as int) * (1.0 - (dayOffset * 0.05))).round() * 60 * 1000;
        final eventTime = dateStart.add(Duration(minutes: i * 35));

        appEvents.add(
          AppUsageEvent(
            id: '${deviceId}_sample_${app['pkg']}_${date.day}_fg',
            deviceId: deviceId,
            packageName: app['pkg'] as String,
            appName: app['name'] as String,
            eventType: 'MOVE_TO_FOREGROUND',
            timestamp: eventTime,
            durationMs: durMs,
          ),
        );
      }
    }
    await _repository.saveAppUsageEvents(appEvents);

    // 4. Screen Activities
    final screenActs = <ScreenActivity>[];
    for (int i = 0; i < 15; i++) {
      final actTime = now.subtract(Duration(minutes: i * 45));
      screenActs.add(
        ScreenActivity(
          id: '${deviceId}_screen_sample_$i',
          deviceId: deviceId,
          eventType: i % 2 == 0 ? 'SCREEN_INTERACTIVE' : 'SCREEN_NON_INTERACTIVE',
          timestamp: actTime,
        ),
      );
      if (i % 3 == 0) {
        screenActs.add(
          ScreenActivity(
            id: '${deviceId}_screen_lock_$i',
            deviceId: deviceId,
            eventType: 'KEYGUARD_HIDDEN',
            timestamp: actTime.subtract(const Duration(seconds: 2)),
          ),
        );
      }
    }
    await _repository.saveScreenActivities(screenActs);

    // 5. Battery Records
    final batteryRecords = <BatteryRecord>[];
    for (int i = 0; i < 12; i++) {
      final bTime = now.subtract(Duration(hours: i * 2));
      final level = (95 - (i * 5)).clamp(15, 100);
      batteryRecords.add(
        BatteryRecord(
          id: '${deviceId}_battery_sample_$i',
          deviceId: deviceId,
          batteryLevel: level,
          chargingStatus: i < 3 ? 'CHARGING' : 'DISCHARGING',
          pluggedType: i < 3 ? 'AC' : 'NONE',
          timestamp: bTime,
        ),
      );
    }
    await _repository.saveBatteryRecords(batteryRecords);

    // 6. Network Usage
    final networkRecords = <NetworkUsage>[];
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59);

      networkRecords.add(
        NetworkUsage(
          id: '${deviceId}_sample_wifi_$i',
          deviceId: deviceId,
          networkType: 'WIFI',
          packageName: 'ALL',
          rxBytes: (350 + i * 25) * 1024 * 1024,
          txBytes: (45 + i * 5) * 1024 * 1024,
          startTime: start,
          endTime: end,
          timestamp: end,
        ),
      );

      networkRecords.add(
        NetworkUsage(
          id: '${deviceId}_sample_mobile_$i',
          deviceId: deviceId,
          networkType: 'MOBILE',
          packageName: 'ALL',
          rxBytes: (40 + i * 10) * 1024 * 1024,
          txBytes: (12 + i * 2) * 1024 * 1024,
          startTime: start,
          endTime: end,
          timestamp: end,
        ),
      );
    }
    await _repository.saveNetworkUsages(networkRecords);

    // 7. Notification Metadata (STRICT: no private content)
    final notifMetadata = <NotificationMetadata>[];
    final sampleNotifs = [
      {'pkg': 'com.google.android.gm', 'app': 'Gmail', 'cat': 'email'},
      {'pkg': 'org.khanacademy.android', 'app': 'Khan Academy', 'cat': 'reminder'},
      {'pkg': 'com.duolingo', 'app': 'Duolingo', 'cat': 'reminder'},
      {'pkg': 'com.google.android.calendar', 'app': 'Google Calendar', 'cat': 'event'},
      {'pkg': 'com.whatsapp', 'app': 'WhatsApp', 'cat': 'msg'},
      {'pkg': 'com.google.android.apps.classroom', 'app': 'Classroom', 'cat': 'service'},
    ];

    for (int i = 0; i < 25; i++) {
      final sn = sampleNotifs[i % sampleNotifs.length];
      notifMetadata.add(
        NotificationMetadata(
          id: '${deviceId}_notif_sample_$i',
          deviceId: deviceId,
          packageName: sn['pkg']!,
          appName: sn['app']!,
          category: sn['cat']!,
          timestamp: now.subtract(Duration(minutes: i * 30)),
        ),
      );
    }
    await _repository.saveNotificationMetadata(notifMetadata);

    // 8. Location History (Opt-in sample)
    final locations = <LocationRecord>[
      LocationRecord(
        id: '${deviceId}_loc_sample_1',
        deviceId: deviceId,
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 12.5,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      LocationRecord(
        id: '${deviceId}_loc_sample_2',
        deviceId: deviceId,
        latitude: 37.7752,
        longitude: -122.4188,
        accuracy: 8.0,
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
    ];
    await _repository.saveLocationRecords(locations);

    // 9. Daily Activity Reports for past 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final screenSeconds = (3.5 + (sin(i) * 1.2)).clamp(1.5, 6.0) * 3600;

      await _repository.saveDailyReport(
        DailyActivityReport(
          id: '${deviceId}_report_$dateKey',
          deviceId: deviceId,
          date: dateKey,
          totalScreenTimeSeconds: screenSeconds.toInt(),
          totalNotificationsCount: 18 + (i * 3),
          totalWifiBytes: (380 + i * 20) * 1024 * 1024,
          totalMobileBytes: (50 + i * 5) * 1024 * 1024,
          topApps: {
            'Personal Learning OS': (120 * 60 * 1000),
            'Google Docs': (85 * 60 * 1000),
            'Khan Academy': (60 * 60 * 1000),
            'Duolingo': (45 * 60 * 1000),
          },
          generatedAt: date,
        ),
      );
    }
  }
}

