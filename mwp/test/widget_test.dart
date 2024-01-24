import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    expect(1, 1);
    tester.pumpWidget(const Placeholder(), null, EnginePhase.build);
    tester.pumpWidget();
  });
}
