import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTree({VoidCallback? layoutCallback, VoidCallback? paintCallback}) {
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
            TestRenderWidget(
              key: const ValueKey('me'),
              layoutCallback: layoutCallback,
              paintCallback: paintCallback,
              child: const TestWidget(
                key: ValueKey('child'),
                child: TestWidget(
                  key: ValueKey('grandchild'),
                ),
              ),
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

void testMeCannotMarkDirtyDuringLayout(String relative) {
  testWidgets('Me cannot mark widget "$relative" as dirty during layout.', (WidgetTester tester) async {
    bool dirtyTree = false;
    int control = 0;

    void callback() {
      if (dirtyTree) {
        control++;
        expect(
          () => markWidgetDirty(tester, relative),
          throwsAFlutterError('Build scheduled during frame.'),
        );
      }
    }

    await tester.pumpWidget(buildTree(
      layoutCallback: callback,
    ));

    dirtyTree = true;
    markRenderObjectDirtyForLayout(tester, 'me');
    expect(control, 0);
    await tester.pump();
    expect(control, 1);
  });
}

void testMeCannotMarkDirtyDuringPaint(String relative) {
  testWidgets('Me cannot mark widget "$relative" as dirty during paint.', (WidgetTester tester) async {
    bool dirtyTree = false;
    int control = 0;

    void callback() {
      if (dirtyTree) {
        control++;
        expect(
          () => markWidgetDirty(tester, relative),
          throwsAFlutterError('Build scheduled during frame.'),
        );
      }
    }

    await tester.pumpWidget(buildTree(
      paintCallback: callback,
    ));

    dirtyTree = true;
    markRenderObjectDirtyForLayout(tester, 'me');
    expect(control, 0);
    await tester.pump();
    expect(control, 1);
  });
}

void main() {
  testMeCannotMarkDirtyDuringLayout('root');
  testMeCannotMarkDirtyDuringLayout('grandparent');
  testMeCannotMarkDirtyDuringLayout('older pibling');
  testMeCannotMarkDirtyDuringLayout('parent');
  testMeCannotMarkDirtyDuringLayout('younger pibling');
  testMeCannotMarkDirtyDuringLayout('older sibling');
  testMeCannotMarkDirtyDuringLayout('me');
  testMeCannotMarkDirtyDuringLayout('younger sibling');
  testMeCannotMarkDirtyDuringLayout('older nibling');
  testMeCannotMarkDirtyDuringLayout('child');
  testMeCannotMarkDirtyDuringLayout('younger nibling');
  testMeCannotMarkDirtyDuringLayout('grandchild');

  testMeCannotMarkDirtyDuringPaint('root');
  testMeCannotMarkDirtyDuringPaint('grandparent');
  testMeCannotMarkDirtyDuringPaint('older pibling');
  testMeCannotMarkDirtyDuringPaint('parent');
  testMeCannotMarkDirtyDuringPaint('younger pibling');
  testMeCannotMarkDirtyDuringPaint('older sibling');
  testMeCannotMarkDirtyDuringPaint('me');
  testMeCannotMarkDirtyDuringPaint('younger sibling');
  testMeCannotMarkDirtyDuringPaint('older nibling');
  testMeCannotMarkDirtyDuringPaint('child');
  testMeCannotMarkDirtyDuringPaint('younger nibling');
  testMeCannotMarkDirtyDuringPaint('grandchild');
}

void markWidgetDirty(WidgetTester tester, String key) {
  tester.element(find.byKey(ValueKey(key))).markNeedsBuild();
}

void markRenderObjectDirtyForLayout(WidgetTester tester, String key) {
  tester.renderObject(find.byKey(ValueKey(key))).markNeedsLayout();
}

void markRenderObjectDirtyForPaint(WidgetTester tester, String key) {
  tester.renderObject(find.byKey(ValueKey(key))).markNeedsPaint();
}

Matcher throwsAFlutterError(String message) {
  return throwsA(isA<FlutterError>().having((e) => e.toString(), 'message', contains(message)));
}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox(key: ValueKey('leaf'));
  }
}

class TestRenderWidget extends SingleChildRenderObjectWidget {
  const TestRenderWidget({super.key, this.layoutCallback, this.paintCallback, super.child});

  final VoidCallback? layoutCallback;
  final VoidCallback? paintCallback;

  @override
  TestRender createRenderObject(BuildContext context) {
    return TestRender(layoutCallback: layoutCallback, paintCallback: paintCallback);
  }

  @override
  void updateRenderObject(BuildContext context, TestRender renderObject) {
    renderObject
      ..layoutCallback = layoutCallback
      ..paintCallback = paintCallback;
  }
}

class TestRender extends RenderProxyBox {
  TestRender({VoidCallback? layoutCallback, VoidCallback? paintCallback}) : _layoutCallback = layoutCallback, _paintCallback = paintCallback;

  VoidCallback? get layoutCallback => _layoutCallback;
  VoidCallback? _layoutCallback;
  set layoutCallback(VoidCallback? callback) {
    if (callback == _layoutCallback) {
      return;
    }
    _layoutCallback = callback;
    markNeedsLayout();
  }

  VoidCallback? get paintCallback => _paintCallback;
  VoidCallback? _paintCallback;
  set paintCallback(VoidCallback? callback) {
    if (callback == _paintCallback) {
      return;
    }
    _paintCallback = callback;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    layoutCallback?.call();
    super.performLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCallback?.call();
    super.paint(context, offset);
  }
}