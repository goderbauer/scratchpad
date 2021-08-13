import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that inserts a [RenderAbstractViewport] into the render tree
/// to increase the [ViewportNotificationMixin.depth] of scroll notifications
/// bubbling up.
///
/// This may be used if two [Scrollable]s are nested within each other to
/// properly differentiate the [ScrollNotification]s produced by them.
class FakeViewport extends SingleChildRenderObjectWidget {
  /// Creates a [FakeViewport].
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
    // TODO(goderbauer): Figure out what to do here.
    return RevealedOffset(offset: 0.0, rect: rect ?? target.paintBounds);
  }
}
