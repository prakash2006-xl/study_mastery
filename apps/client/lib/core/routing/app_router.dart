import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/main_shell.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/serious_study/presentation/serious_study_screen.dart';
import '../../features/scribble/presentation/scribble_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/alarms/presentation/alarms_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/music/presentation/music_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, state) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/library', builder: (context, state) => const LibraryScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/notes', builder: (context, state) => const NotesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/alarms', builder: (context, state) => const AlarmsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/focus', builder: (context, state) => const FocusScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/music', builder: (context, state) => const MusicScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/serious_study',
        builder: (context, state) {
          final extraData = state.extra as Map<String, String>?;
          return SeriousStudyScreen(
            filePath: extraData?['filePath'],
            documentId: extraData?['documentId'],
          );
        },
      ),
      GoRoute(
        path: '/scribble',
        builder: (context, state) => const ScribbleScreen(),
      ),
    ],
  );
});

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - Coming Soon', style: const TextStyle(fontSize: 24))),
    );
  }
}
