import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTree(Function meBuilder) {
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
              Builder(
                key: const ValueKey('me'),
                builder: (BuildContext context) {
                  const  Widget child = SizedBox(
                      key: ValueKey('child'),
                      child: SizedBox(
                        key: ValueKey('grandchild'),
                      )
                  );
                  return meBuilder(context, child);
                },
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

void testMeCanMarkRenderObjectDirtyDuringBuild(String relative) {
  testWidgets('Me can mark RenderObject "$relative" as dirty during build.', (WidgetTester tester) async {
    bool dirtyTree = false;
    await tester.pumpWidget(buildTree((BuildContext context, Widget child) {
      if (dirtyTree) {
        markRenderObjectDirty(tester, relative);
      }
      return child;
    }));

    dirtyTree = true;
    markWidgetDirty(tester, 'me');
    await tester.pump();
  });
}

void main() {
  testMeCanMarkRenderObjectDirtyDuringBuild('root');
  testMeCanMarkRenderObjectDirtyDuringBuild('grandparent');
  testMeCanMarkRenderObjectDirtyDuringBuild('older pibling');
  testMeCanMarkRenderObjectDirtyDuringBuild('parent');
  testMeCanMarkRenderObjectDirtyDuringBuild('younger pibling');
  testMeCanMarkRenderObjectDirtyDuringBuild('older sibling');
  testMeCanMarkRenderObjectDirtyDuringBuild('me');
  testMeCanMarkRenderObjectDirtyDuringBuild('younger sibling');
  testMeCanMarkRenderObjectDirtyDuringBuild('older nibling');
  testMeCanMarkRenderObjectDirtyDuringBuild('child');
  testMeCanMarkRenderObjectDirtyDuringBuild('younger nibling');
  testMeCanMarkRenderObjectDirtyDuringBuild('grandchild');
}

void markWidgetDirty(WidgetTester tester, String key) {
  tester.element(find.byKey(ValueKey(key))).markNeedsBuild();
}

void markRenderObjectDirty(WidgetTester tester, String key) {
  tester.renderObject(find.byKey(ValueKey(key))).markNeedsLayout();
}
