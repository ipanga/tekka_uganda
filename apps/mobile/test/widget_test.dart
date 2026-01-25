import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tekka/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TekkaApp(),
      ),
    );

    // Verify that the app renders (will show phone input due to auth redirect)
    await tester.pumpAndSettle();

    // Basic smoke test - app should render without crashing
    expect(find.byType(TekkaApp), findsOneWidget);
  });
}
