import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/top_header.dart';
import 'widgets/summary_cards.dart';
import 'widgets/task_panel.dart';
import 'widgets/study_overview.dart';
import 'widgets/focus_timer.dart';
import 'widgets/alarm_panel.dart';
import 'widgets/schedule_panel.dart';
import 'widgets/quick_notes.dart';
import 'widgets/recent_activity.dart';
import 'widgets/streak_calendar.dart';
import 'widgets/motivation_card.dart';
import 'widgets/keep_focused.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;
          final isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1200;

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: TopHeader(
                  title: 'Growth Dashboard',
                  subtitle: 'Plan. Focus. Learn. Grow.',
                ),
              ),
              const SliverToBoxAdapter(
                child: SummaryCardsRow(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverToBoxAdapter(
                  child: isDesktop 
                      ? _buildDesktopLayout() 
                      : (isTablet ? _buildTabletLayout() : _buildMobileLayout()),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Tasks & Recent Activity
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 520, child: TaskPanel()),
              const SizedBox(height: 16),
              const SizedBox(height: 250, child: RecentActivityPanel()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Column 2: Study Overview, Keep Focused, Quick Notes
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 320, child: StudyOverview()),
              const SizedBox(height: 16),
              const SizedBox(height: 160, child: KeepFocusedWidget()),
              const SizedBox(height: 16),
              const SizedBox(height: 274, child: QuickNotesPanel()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Column 3: Upcoming Alarms, Schedule
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 380, child: AlarmPanel()),
              const SizedBox(height: 16),
              const SizedBox(height: 390, child: SchedulePanel()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Column 4: Focus Timer, Calendar, Motivation
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 310, child: FocusTimer()),
              const SizedBox(height: 16),
              const SizedBox(height: 300, child: StreakCalendar()),
              const SizedBox(height: 16),
              const SizedBox(height: 200, child: MotivationCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const SizedBox(height: 520, child: TaskPanel()),
              const SizedBox(height: 16),
              const SizedBox(height: 320, child: StudyOverview()),
              const SizedBox(height: 16),
              const SizedBox(height: 250, child: RecentActivityPanel()),
              const SizedBox(height: 16),
              const SizedBox(height: 280, child: QuickNotesPanel()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Column 2
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const SizedBox(height: 310, child: FocusTimer()),
              const SizedBox(height: 16),
              const SizedBox(height: 160, child: KeepFocusedWidget()),
              const SizedBox(height: 16),
              const SizedBox(height: 380, child: AlarmPanel()),
              const SizedBox(height: 16),
              const SizedBox(height: 390, child: SchedulePanel()),
              const SizedBox(height: 16),
              const SizedBox(height: 300, child: StreakCalendar()),
              const SizedBox(height: 16),
              const SizedBox(height: 200, child: MotivationCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const SizedBox(height: 520, child: TaskPanel()),
        const SizedBox(height: 16),
        const SizedBox(height: 310, child: FocusTimer()),
        const SizedBox(height: 16),
        const SizedBox(height: 160, child: KeepFocusedWidget()),
        const SizedBox(height: 16),
        const SizedBox(height: 320, child: StudyOverview()),
        const SizedBox(height: 16),
        const SizedBox(height: 380, child: AlarmPanel()),
        const SizedBox(height: 16),
        const SizedBox(height: 390, child: SchedulePanel()),
        const SizedBox(height: 16),
        const SizedBox(height: 280, child: QuickNotesPanel()),
        const SizedBox(height: 16),
        const SizedBox(height: 300, child: StreakCalendar()),
        const SizedBox(height: 16),
        const SizedBox(height: 250, child: RecentActivityPanel()),
        const SizedBox(height: 16),
        const SizedBox(height: 200, child: MotivationCard()),
      ],
    );
  }
}
