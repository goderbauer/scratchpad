import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTree(Function meBuilder) {
  return Directionality(
    key: const ValueKey('root'),
    textDirection: TextDirection.ltr,
    child: Row(
      key: const ValueKey('grandparent'),
      children: [
        const TestWidget(
          key: ValueKey('older pibling'),
        ),
        Row(
          key: const ValueKey('parent'),
          children: [
            const TestWidget(
              key: ValueKey('older sibling'),
              child: TestWidget(
                key: ValueKey('older nibling'),
              ),
            ),
            Builder(
              key: const ValueKey('me'),
              builder: (BuildContext context) {
                const  Widget child = TestWidget(
                  key: ValueKey('child'),
                  child: TestWidget(
                    key: ValueKey('grandchild'),
                  )
                );
                return meBuilder(context, child);
              },
            ),
            const TestWidget(
              key: ValueKey('younger sibling'),
              child: TestWidget(
                key: ValueKey('younger nibling'),
              ),
            ),
          ],
        ),
        const TestWidget(
          key: ValueKey('younger pibling'),
        ),
      ],
    ),
  );
}

void testMeCannotMarkDirtyDuringBuild(String relative) {
  testWidgets('Me cannot mark "$relative" as dirty during build.', (WidgetTester tester) async {
    bool dirtyTree = false;
    await tester.pumpWidget(buildTree((BuildContext context, Widget child) {
      if (dirtyTree) {
        expect(
          () => markDirty(tester, relative),
          throwsAFlutterError('A widget can be marked as needing to be built during the build phase only if one of its ancestors is currently building.'),
        );
      }
      return child;
    }));

    dirtyTree = true;
    markDirty(tester, 'me');
    await tester.pump();
  });
}

void testMeCanMarkDirtyDuringBuild(String relative) {
  testWidgets('Me can mark "$relative" as dirty during build.', (WidgetTester tester) async {
    bool dirtyTree = false;
    await tester.pumpWidget(buildTree((BuildContext context, Widget child) {
      if (dirtyTree) {
        markDirty(tester, relative);
      }
      return child;
    }));

    dirtyTree = true;
    markDirty(tester, 'me');
    await tester.pump();
  });
}

Widget buildTreeWithLayoutBuilder(Function meBuilder) {
  return Directionality(
    key: const ValueKey('root'),
    textDirection: TextDirection.ltr,
    child: Row(
      key: const ValueKey('grandparent'),
      children: [
        const TestWidget(
          key: ValueKey('older pibling'),
        ),
        Row(
          key: const ValueKey('parent'),
          children: [
            const TestWidget(
              key: ValueKey('older sibling'),
              child: TestWidget(
                key: ValueKey('older nibling'),
              ),
            ),
            LayoutBuilder(
              key: const ValueKey('me'),
              builder: (BuildContext context, BoxConstraints constraints) {
                const  Widget child = TestWidget(
                    key: ValueKey('child'),
                    child: TestWidget(
                      key: ValueKey('grandchild'),
                    )
                );
                return meBuilder(context, child);
              },
            ),
            const TestWidget(
              key: ValueKey('younger sibling'),
              child: TestWidget(
                key: ValueKey('younger nibling'),
              ),
            ),
          ],
        ),
        const TestWidget(
          key: ValueKey('younger pibling'),
        ),
      ],
    ),
  );
}

void testLayoutBuilderMeCannotMarkDirtyDuringBuild(String relative) {
  testWidgets('LayoutBuilder me cannot mark "$relative" as dirty during build.', (WidgetTester tester) async {
    bool dirtyTree = false;
    int control = 0;
    await tester.pumpWidget(buildTree((BuildContext context, Widget child) {
      if (dirtyTree) {
        control++;
        expect(
          () => markDirty(tester, relative),
          throwsAFlutterError('A widget can be marked as needing to be built during the build phase only if one of its ancestors is currently building.'),
        );
      }
      return child;
    }));

    dirtyTree = true;
    markDirty(tester, 'me');
    expect(control, 0);
    await tester.pump();
    expect(control, 1);
  });
}

void testLayoutBuilderMeCanMarkDirtyDuringBuild(String relative) {
  testWidgets('LayoutBuilder me can mark "$relative" as dirty during build.', (WidgetTester tester) async {
    bool dirtyTree = false;
    int control = 0;
    await tester.pumpWidget(buildTreeWithLayoutBuilder((BuildContext context, Widget child) {
      if (dirtyTree) {
        control++;
        markDirty(tester, relative);
      }
      return child;
    }));

    dirtyTree = true;
    markDirty(tester, 'me');
    expect(control, 0);
    await tester.pump();
    expect(control, 1);
  });
}

void main() {
  testMeCannotMarkDirtyDuringBuild('root');
  testMeCannotMarkDirtyDuringBuild('grandparent');
  testMeCannotMarkDirtyDuringBuild('older pibling');
  testMeCannotMarkDirtyDuringBuild('parent');
  testMeCannotMarkDirtyDuringBuild('younger pibling');
  testMeCannotMarkDirtyDuringBuild('older sibling');
  testMeCanMarkDirtyDuringBuild('me');
  testMeCannotMarkDirtyDuringBuild('younger sibling');
  testMeCannotMarkDirtyDuringBuild('older nibling');
  testMeCanMarkDirtyDuringBuild('child');
  testMeCannotMarkDirtyDuringBuild('younger nibling');
  testMeCanMarkDirtyDuringBuild('grandchild');

  testLayoutBuilderMeCannotMarkDirtyDuringBuild('root');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('grandparent');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('older pibling');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('parent');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('younger pibling');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('older sibling');
  testLayoutBuilderMeCanMarkDirtyDuringBuild('me');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('younger sibling');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('older nibling');
  testLayoutBuilderMeCanMarkDirtyDuringBuild('child');
  testLayoutBuilderMeCannotMarkDirtyDuringBuild('younger nibling');
  testLayoutBuilderMeCanMarkDirtyDuringBuild('grandchild');
}

void markDirty(WidgetTester tester, String key) {
  tester.element(find.byKey(ValueKey(key))).markNeedsBuild();
}

Matcher throwsAFlutterError(String message) {
  return throwsA(isA<FlutterError>().having((e) =>  e.toString(), 'message', contains(message)));
}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox(key: ValueKey('leaf'));
  }
}
