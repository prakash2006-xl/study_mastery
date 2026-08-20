import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:personal_learning_os_client/main.dart';

void main() {
  testWidgets('App boots and shows Dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PersonalLearningOS()));

    // Verify that the Dashboard is rendered.
    expect(find.text('Personal Learning OS'), findsOneWidget);
    expect(find.text('Serious Study Mode'), findsOneWidget);
  });
}
