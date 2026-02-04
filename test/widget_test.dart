import 'package:flutter_test/flutter_test.dart';
import 'package:bee_match3/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppRoot());

    // Verify that splash screen loads
    expect(find.text('Idle Bee '), findsOneWidget);
    expect(find.text('TAP TO START'), findsOneWidget);
  });
}
