import 'package:flutter_test/flutter_test.dart';
import 'package:semis_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SemisApp());

    // Verify SEMIS title exists in LoginScreen
    expect(find.text('SEMIS'), findsOneWidget);
  });
}
