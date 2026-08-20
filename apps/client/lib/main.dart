import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/theme.dart';
import 'core/filesystem/filesystem_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize offline file paths before anything else boots
  await FilesystemService.initialize();
  debugPrint('LearningOS initialized at: ${FilesystemService.appDocDir.path}');

  runApp(
    const ProviderScope(
      child: PersonalLearningOS(),
    ),
  );
}

class PersonalLearningOS extends ConsumerWidget {
  const PersonalLearningOS({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Personal Learning OS',
      theme: AntigravityTheme.lightTheme,
      darkTheme: AntigravityTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
