import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTree({VoidCallback? layoutCallback, VoidCallback? paintCallback}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      key: const ValueKey('root'),
      child: Row(
        key: const ValueKey('grandparent'),
        children: [
          const SizedBox(
            key: ValueKey('older pibling'),
          ),
          Row(
            key: const ValueKey('parent'),
            children: [
              const SizedBox(
                key: ValueKey('older sibling'),
                child: SizedBox(
                  key: ValueKey('older nibling'),
                ),
              ),
              TestRenderWidget(
                key: const ValueKey('me'),
                layoutCallback: layoutCallback,
                paintCallback: paintCallback,
                child: const SizedBox(
                  key: ValueKey('child'),
                  child: SizedBox(
                    key: ValueKey('grandchild'),
                  ),
                ),
              ),
              const SizedBox(
                key: ValueKey('younger sibling'),
                child: SizedBox(
                  key: ValueKey('younger nibling'),
                ),
              ),
            ],
          ),
          const SizedBox(
            key: ValueKey('younger pibling'),
          ),
        ],
      ),
    ),
  );
}

void testMeCannotMarkDirtyDuringLayout(String relative, FailureReason reason) {
  final String error;
  switch (reason) {
    case FailureReason.ancestor:
      error = 'The RenderObject was mutated when none of its ancestors is actively performing layout.';
      break;
    case FailureReason.self:
      error = 'A RenderObject must not re-dirty itself while still being laid out.';
      break;
    case FailureReason.subtree:
      error = 'A RenderObject must not mutate another RenderObject from a different render subtree in its performLayout method.';
      break;
    case FailureReason.descendant:
      error = 'A RenderObject must not mutate its descendants in its performLayout method.';
      break;
  }

  testWidgets('Me cannot mark RenderObject "$relative" as dirty during layout.', (WidgetTester tester) async {
    bool dirtyTree = false;
    int control = 0;

    void callback() {
      if (dirtyTree) {
        control++;
        expect(
          () => markRenderObjectDirtyForLayout(tester, relative),
          throwsAFlutterError(error),
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
  testWidgets('Me cannot mark RenderObject "$relative" as dirty during paint.', (WidgetTester tester) async {
    bool dirtyTree = false;
    int control = 0;

    void callback() {
      if (dirtyTree) {
        control++;
        markRenderObjectDirtyForLayout(tester, relative);
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
  testMeCannotMarkDirtyDuringLayout('root', FailureReason.ancestor);
  testMeCannotMarkDirtyDuringLayout('grandparent', FailureReason.self);
  testMeCannotMarkDirtyDuringLayout('older pibling', FailureReason.subtree);
  testMeCannotMarkDirtyDuringLayout('parent', FailureReason.self);
  testMeCannotMarkDirtyDuringLayout('younger pibling', FailureReason.subtree);
  testMeCannotMarkDirtyDuringLayout('older sibling', FailureReason.subtree);
  testMeCannotMarkDirtyDuringLayout('me', FailureReason.self);
  testMeCannotMarkDirtyDuringLayout('younger sibling', FailureReason.subtree);
  testMeCannotMarkDirtyDuringLayout('older nibling', FailureReason.subtree);
  testMeCannotMarkDirtyDuringLayout('child', FailureReason.descendant);
  testMeCannotMarkDirtyDuringLayout('younger nibling', FailureReason.subtree);
  testMeCannotMarkDirtyDuringLayout('grandchild', FailureReason.descendant);

  // These should all fail with an assertion error, need to figure out how to catch.
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

enum FailureReason {
  ancestor,
  self,
  subtree,
  descendant,
}