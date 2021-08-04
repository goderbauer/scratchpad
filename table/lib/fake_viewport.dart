import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class FakeViewport extends SingleChildRenderObjectWidget {
  const FakeViewport({
    Key? key,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFakeViewport();
}

class _RenderFakeViewport extends RenderProxyBox implements RenderAbstractViewport {
  _RenderFakeViewport({
    RenderBox? child,
  }) : super(child);

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment, {Rect? rect}) {
    // TODO: figure out what to do here
    return RevealedOffset(offset: 0.0, rect: rect ?? target.paintBounds);
  }
}
