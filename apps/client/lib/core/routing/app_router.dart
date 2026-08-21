import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/main_shell.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/serious_study/presentation/serious_study_screen.dart';
import '../../features/scribble/presentation/scribble_screen.dart';

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
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
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
