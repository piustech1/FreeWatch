import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freewatch/app.dart';

void main() {
  testWidgets('FreeWatchApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: FreeWatchApp()),
    );

    // Verify basic smoke test passes
    expect(find.byType(FreeWatchApp), findsOneWidget);
  });
}
