import 'dart:convert';
import 'package:ephemeral/ephemeral.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Ephemeral smoke test', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        'JSON.stringify(${jsonEncode([
          {
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'main',
              'catalogId':
                  'https://a2ui.org/specification/v0_9/basic_catalog.json',
            },
          },
          {
            'version': 'v0.9',
            'updateComponents': {
              'surfaceId': 'main',
              'components': [
                {
                  'id': 'root',
                  'component': 'Text',
                  'text': 'Smoke test success',
                },
              ],
            },
          },
        ])});',
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Ephemeral(
          url: Uri.parse('https://example.com/smoke.js'),
          client: mockClient,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Smoke test success'), findsOneWidget);
  });
}
