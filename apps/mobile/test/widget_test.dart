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

    // Let the first frame settle. We can't pumpAndSettle here because the
    // app legitimately runs long-lived streams (deep-link, connectivity,
    // auth) that never quiesce.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TekkaApp), findsOneWidget);
  });
}
