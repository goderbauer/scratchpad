import 'dart:convert';
import 'dart:io';
import 'package:ephemeral/ephemeral.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle(this.content);
  final String content;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return content;
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  testWidgets(
    'Ephemeral widget fetches JS, evaluates it, and renders genui components',
    (WidgetTester tester) async {
      final sampleA2uiPayload = jsonEncode([
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
                'text': 'Hello from Ephemeral JS!',
              },
            ],
          },
        },
      ]);

      final jsCode = 'JSON.stringify($sampleA2uiPayload);';

      final mockClient = MockClient((request) async {
        if (request.url == Uri.parse('https://example.com/ui.js')) {
          return http.Response(jsCode, 200);
        }
        return http.Response('Not Found', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ephemeral(
              url: Uri.parse('https://example.com/ui.js'),
              client: mockClient,
            ),
          ),
        ),
      );

      // Verify progress indicator while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Allow async JS execution and widget build to complete
      await tester.pumpAndSettle();

      // Verify the rendered GenUI component text
      expect(find.text('Hello from Ephemeral JS!'), findsOneWidget);
    },
  );

  testWidgets(
    'Ephemeral.asset loads JS from asset bundle and renders genui components',
    (WidgetTester tester) async {
      final sampleA2uiPayload = jsonEncode([
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
                'text': 'Hello from Asset JS!',
              },
            ],
          },
        },
      ]);

      final jsCode = 'JSON.stringify($sampleA2uiPayload);';
      final bundle = TestAssetBundle(jsCode);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ephemeral.asset(
              assetPath: 'assets/ui.js',
              assetBundle: bundle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Hello from Asset JS!'), findsOneWidget);
    },
  );

  testWidgets(
    'Ephemeral.asset renders counter UI from counter JS asset',
    (WidgetTester tester) async {
      final counterJs = File('assets/counter.js').readAsStringSync();
      final bundle = TestAssetBundle(counterJs);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ephemeral.asset(
              assetPath: 'assets/counter.js',
              assetBundle: bundle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Counter App'), findsOneWidget);
      expect(find.text('Current count: 0'), findsOneWidget);
      expect(find.text('Increment (+)'), findsOneWidget);
      expect(find.text('Decrement (-)'), findsOneWidget);
    },
  );

  testWidgets(
    'Ephemeral listens to button presses and emits onUiEvent',
    (WidgetTester tester) async {
      final counterJs = File('assets/counter.js').readAsStringSync();
      final bundle = TestAssetBundle(counterJs);

      String? receivedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ephemeral.asset(
              assetPath: 'assets/counter.js',
              assetBundle: bundle,
              onUiEvent: (eventJson) {
                receivedEvent = eventJson;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current count: 0'), findsOneWidget);

      await tester.tap(find.text('Increment (+)'));
      await tester.pumpAndSettle();

      expect(receivedEvent, isNotNull);
      expect(receivedEvent, contains('increment'));
      expect(find.text('Current count: 1'), findsOneWidget);

      await tester.tap(find.text('Decrement (-)'));
      await tester.pumpAndSettle();

      expect(find.text('Current count: 0'), findsOneWidget);
    },
  );

  testWidgets(
    'Ephemeral widget displays error when HTTP fetch fails',
    (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ephemeral(
              url: Uri.parse('https://example.com/bad.js'),
              client: mockClient,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorWidget), findsOneWidget);
    },
  );
}
