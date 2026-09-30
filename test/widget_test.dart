import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freewatch/app.dart';
import 'package:freewatch/features/splash/splash_screen.dart';

void main() {
  testWidgets('FreeWatchApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger an initial frame
    await tester.pumpWidget(
      const ProviderScope(child: FreeWatchApp()),
    );

    // Verify FreeWatchApp and SplashScreen render
    expect(find.byType(FreeWatchApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance clock to verify rendering
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
