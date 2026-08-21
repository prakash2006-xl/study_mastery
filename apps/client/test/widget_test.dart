
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:personal_learning_os_client/main.dart';
import 'package:personal_learning_os_client/features/tasks/application/task_provider.dart';
import 'package:personal_learning_os_client/core/database/task_repository.dart';
import 'package:personal_learning_os_client/features/library/application/document_provider.dart';
import 'package:personal_learning_os_client/core/database/document_repository.dart';

class MockTaskNotifier extends AsyncNotifier<List<StudyTask>> implements TaskNotifier {
  @override
  Future<List<StudyTask>> build() async => [];
  @override
  Future<void> addTask(String title) async {}
  @override
  Future<void> toggleTaskCompletion(StudyTask task) async {}
  @override
  Future<void> deleteTask(String id) async {}
}

class MockDocumentNotifier extends AsyncNotifier<List<Document>> implements DocumentNotifier {
  @override
  Future<List<Document>> build() async => [];
  @override
  Future<void> importDocument(String title, String filePath) async {}
}

void main() {
  testWidgets('App boots and verifies MainShell navigation', (WidgetTester tester) async {
    // Provide mocks to prevent hitting real sqflite in tests
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskNotifierProvider.overrideWith(() => MockTaskNotifier()),
          documentNotifierProvider.overrideWith(() => MockDocumentNotifier()),
        ],
        child: const PersonalLearningOS(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Dashboard is the initial route
    expect(find.text('Growth Dashboard'), findsOneWidget);
    expect(find.text('Add a new study task...'), findsOneWidget);

    // Find the Library tab (on bottom navigation bar or navigation rail)
    final libraryTab = find.text('Library').last;
    expect(libraryTab, findsOneWidget);

    // Tap on the Library tab to navigate
    await tester.tap(libraryTab);
    await tester.pumpAndSettle();

    // Verify Library Screen is now displayed
    expect(find.text('Document Library'), findsOneWidget);
    expect(find.text('No documents in your library.'), findsOneWidget);
  });
}

