import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/family_insights_repository.dart';
import '../data/family_insights_platform_channel.dart';
import 'family_insights_service.dart';
import '../domain/models/device_activity_model.dart';
import '../domain/models/app_usage_model.dart';
import '../domain/models/screen_activity_model.dart';
import '../domain/models/notification_metadata_model.dart';
import '../domain/models/battery_model.dart';
import '../domain/models/network_usage_model.dart';
import '../domain/models/location_model.dart';
import '../domain/models/daily_activity_report_model.dart';

final familyInsightsPlatformProvider = Provider<FamilyInsightsPlatformChannel>((ref) {
  return FamilyInsightsPlatformChannel();
});

final familyInsightsServiceProvider = Provider<FamilyInsightsService?>((ref) {
  final repo = ref.watch(familyInsightsRepositoryProvider);
  final platform = ref.watch(familyInsightsPlatformProvider);
  if (repo == null) return null;
  return FamilyInsightsService(repository: repo, platformChannel: platform);
});

// Refresh trigger state
final familyInsightsRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final deviceActivityListProvider = FutureProvider<List<DeviceActivity>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getAllDevices();
});

final currentDeviceActivityProvider = FutureProvider<DeviceActivity?>((ref) async {
  final devices = await ref.watch(deviceActivityListProvider.future);
  return devices.isNotEmpty ? devices.first : null;
});

final monitoringPermissionsMapProvider = FutureProvider<Map<String, bool>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  final service = ref.watch(familyInsightsServiceProvider);
  if (repo == null) return {};
  if (service != null && service.isPlatformSupported) {
    try {
      await service.checkPermissions();
    } catch (_) {}
  }
  return await repo.getPermissions();
});

final appUsageSummariesProvider = FutureProvider<List<AppUsageSummary>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getAppUsageSummaries();
});

final screenActivitiesProvider = FutureProvider<List<ScreenActivity>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getScreenActivities();
});

final notificationMetadataListProvider = FutureProvider<List<NotificationMetadata>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getNotificationMetadata();
});

final notificationCategoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return {};
  return await repo.getNotificationCategoryCounts();
});

final batteryHistoryListProvider = FutureProvider<List<BatteryRecord>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getBatteryHistory();
});

final latestBatteryRecordProvider = FutureProvider<BatteryRecord?>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return null;
  return await repo.getLatestBatteryRecord(null);
});

final networkUsageListProvider = FutureProvider<List<NetworkUsage>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getNetworkUsage();
});

final locationHistoryListProvider = FutureProvider<List<LocationRecord>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getLocationHistory();
});

final latestLocationRecordProvider = FutureProvider<LocationRecord?>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return null;
  return await repo.getLatestLocation(null);
});

final dailyActivityReportsListProvider = FutureProvider<List<DailyActivityReport>>((ref) async {
  ref.watch(familyInsightsRefreshTriggerProvider);
  final repo = ref.watch(familyInsightsRepositoryProvider);
  if (repo == null) return [];
  return await repo.getDailyReports();
});

final todayActivityReportProvider = FutureProvider<DailyActivityReport?>((ref) async {
  final reports = await ref.watch(dailyActivityReportsListProvider.future);
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  try {
    return reports.firstWhere((r) => r.date == todayKey);
  } catch (_) {
    return reports.isNotEmpty ? reports.first : null;
  }
});

class FamilyInsightsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FamilyInsightsController(this._ref) : super(const AsyncValue.data(null));

  Future<void> syncNow() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(familyInsightsServiceProvider);
      if (service != null) {
        await service.syncNow();
        _ref.read(familyInsightsRefreshTriggerProvider.notifier).state++;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleMonitoringPause(bool currentlyPaused) async {
    try {
      final service = _ref.read(familyInsightsServiceProvider);
      if (service != null) {
        await service.setMonitoringPaused(!currentlyPaused);
        _ref.read(familyInsightsRefreshTriggerProvider.notifier).state++;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLocationMonitoring(bool enable) async {
    try {
      final service = _ref.read(familyInsightsServiceProvider);
      if (service != null) {
        await service.setLocationMonitoringEnabled(enable);
        _ref.read(familyInsightsRefreshTriggerProvider.notifier).state++;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> populateSampleData() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(familyInsightsServiceProvider);
      if (service != null) {
        await service.populateSampleData();
        _ref.read(familyInsightsRefreshTriggerProvider.notifier).state++;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAllData() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(familyInsightsServiceProvider);
      if (service != null) {
        await service.clearAllData();
        _ref.read(familyInsightsRefreshTriggerProvider.notifier).state++;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> exportJson() async {
    final service = _ref.read(familyInsightsServiceProvider);
    if (service != null) {
      return await service.exportDataAsJson();
    }
    return '';
  }

  Future<String> exportCsv(String type) async {
    final service = _ref.read(familyInsightsServiceProvider);
    if (service != null) {
      return await service.exportDataAsCsv(type);
    }
    return '';
  }
}

final familyInsightsControllerProvider =
    StateNotifierProvider<FamilyInsightsController, AsyncValue<void>>((ref) {
  return FamilyInsightsController(ref);
});

