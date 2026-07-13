import 'package:ephemeral/main_http.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HttpEphemeralApp hides URL input after tapping Load',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HttpEphemeralApp());

    // Initially embedded TextField and Load button are visible
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Load'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);

    // Tap Load button
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();

    // After loading once, URL input row and edit icon are hidden, refresh button is present
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Load'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
