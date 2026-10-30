import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/family_insights_provider.dart';
import 'widgets/privacy_disclosure_banner.dart';
import 'widgets/unsupported_platform_banner.dart';
import 'widgets/monitoring_status_card.dart';
import 'widgets/app_usage_dashboard_view.dart';
import 'widgets/screen_activity_timeline_view.dart';
import 'widgets/notification_metadata_view.dart';
import 'widgets/battery_history_view.dart';
import 'widgets/network_usage_view.dart';
import 'widgets/location_history_view.dart';
import 'widgets/daily_weekly_reports_view.dart';
import 'widgets/export_dialog.dart';

class FamilyInsightsScreen extends ConsumerStatefulWidget {
  const FamilyInsightsScreen({super.key});

  @override
  ConsumerState<FamilyInsightsScreen> createState() => _FamilyInsightsScreenState();
}

class _FamilyInsightsScreenState extends ConsumerState<FamilyInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
    Tab(icon: Icon(Icons.apps_rounded), text: 'Apps'),
    Tab(icon: Icon(Icons.timeline_rounded), text: 'Screen'),
    Tab(icon: Icon(Icons.notifications_none_rounded), text: 'Notifs'),
    Tab(icon: Icon(Icons.battery_charging_full_rounded), text: 'Battery'),
    Tab(icon: Icon(Icons.network_check_rounded), text: 'Network'),
    Tab(icon: Icon(Icons.location_on_outlined), text: 'Location'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDeleteDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Clear All Monitoring Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all stored application usage events, screen activities, notification metadata, battery history, network stats, and daily reports from this local device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(familyInsightsControllerProvider.notifier).clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All local monitoring data deleted.')),
              );
            },
            child: const Text('Delete Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom_rounded, color: Colors.purpleAccent, size: 28),
            SizedBox(width: 10),
            Text('Family Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export JSON / CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const ExportDialog(),
              );
            },
          ),
          IconButton(
            tooltip: 'Clear All Monitoring Data',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _showDeleteDataConfirmation(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    UnsupportedPlatformBanner(),
                    PrivacyDisclosureBanner(),
                    MonitoringStatusCard(),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: _tabs,
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: DailyWeeklyReportsView(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: AppUsageDashboardView(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: ScreenActivityTimelineView(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: NotificationMetadataView(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: BatteryHistoryView(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: NetworkUsageView(),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: LocationHistoryView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}

