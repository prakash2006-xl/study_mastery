import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/serious_study/presentation/serious_study_screen.dart';
import '../../features/scribble/presentation/scribble_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/serious_study',
        builder: (context, state) => const SeriousStudyScreen(),
      ),
      GoRoute(
        path: '/scribble',
        builder: (context, state) => const ScribbleScreen(),
      ),
    ],
  );
});
