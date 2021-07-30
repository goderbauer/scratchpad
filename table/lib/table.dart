import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class RawTableScrollView extends StatefulWidget {
  const RawTableScrollView({Key? key, this.horizontalController, this.verticalController, required this.delegate}) : super(key: key);

  final ScrollController? horizontalController;
  final ScrollController? verticalController;

  final RawTableDelegate delegate;

  @override
  State<RawTableScrollView> createState() => _RawTableScrollViewState();
}

class _RawTableScrollViewState extends State<RawTableScrollView> {
  // TODO: Allow passing in a TableScrollController(). (This is obviously not safe)
  late final ScrollController horizontalController = widget.horizontalController ?? ScrollController();
  late final ScrollController verticalController = widget.verticalController ?? ScrollController();

  @override
  Widget build(BuildContext context) {
    // TODO: Figure out scrollbar situation.
    // TODO: deal with panning
    return Scrollbar(
      controller: horizontalController,
      isAlwaysShown: true,
      child: Scrollbar(
        controller: verticalController,
        isAlwaysShown: true,
        notificationPredicate: (ScrollNotification notification) => notification.depth == 1,
        child: Scrollable(
          controller: horizontalController,
          axisDirection: AxisDirection.right, // TODO: make these configurable
          viewportBuilder: (BuildContext context, ViewportOffset horizontalOffset) {
            return Scrollable(
              controller: verticalController,
              axisDirection: AxisDirection.down,
              viewportBuilder: (BuildContext context, ViewportOffset verticalOffset) {
                return _RawTableViewport(
                  horizontalOffset: horizontalOffset,
                  verticalOffset: verticalOffset,
                  delegate: widget.delegate,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// TODO: Implement viewport interface.
class _RawTableViewport extends RenderObjectWidget {
  const _RawTableViewport({
    Key? key,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.delegate,
  }) : super(key: key);

  final ViewportOffset horizontalOffset;
  final ViewportOffset verticalOffset;
  final RawTableDelegate delegate;

  @override
  RenderObjectElement createElement() => _RawTableViewportElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRawTableViewport(
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      delegate: delegate,
      cellManager: context as _RawTableViewportElement,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderRawTableViewport renderObject) {
    assert(identical(context, renderObject.cellManager));
    renderObject
      ..horizontalOffset = horizontalOffset
      ..verticalOffset = verticalOffset
      ..delegate = delegate;
  }
}

class _RawTableViewportElement extends RenderObjectElement implements _CellManager {
  _RawTableViewportElement(_RawTableViewport widget) : super(widget);

  // ---- Specializing the getters ----

  @override
  _RawTableViewport get widget => super.widget as _RawTableViewport;

  @override
  _RenderRawTableViewport get renderObject => super.renderObject as _RenderRawTableViewport;

  final Map<_CellIndex, Element> _children = <_CellIndex, Element>{};

  // ---- Updating children ----

  // @override
  // void mount(Element? parent, Object? newSlot) {
  //   // Create the initial list of element children from widget children by calling updateChild.
  //   // We don't have any pre-determined widget children, so nothing to do here.
  //   super.mount(parent, newSlot);
  // }

  @override
  void update(_RawTableViewport newWidget) {
    // Rebuild if the delegate requires it. (Rebuild will delegate to layout).
    final _RawTableViewport oldWidget = widget;
    super.update(newWidget);
    final RawTableDelegate newDelegate = newWidget.delegate;
    final RawTableDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate && (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate))) {
      rebuild(); // ultimately runs performRebuild()
      // renderObject.markNeedsLayoutWithRebuild(); // rebuild(); // TODO: or performRebuild? or remove performRebuild impl alltogether and just mark renderobject?
    }
  }

  // TODO: check inheritedwidgets.
  @override
  void performRebuild() {
    super.performRebuild();
    // Children list is updated during layout since we only know during layout
    // which children will be visible.
    renderObject.markNeedsLayoutWithRebuild();
  }

  // @override
  // void reassemble() {
  //   super.reassemble();
  //   // Makes buildCell in delegate hot-reloadable.
  //   renderObject.markNeedsLayoutWithRebuild();
  // }

  // ---- Detaching children ----

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);
    _children.remove(child.slot);
  }

  // ---- Maintaining the render object tree ----

  @override
  void insertRenderObjectChild(RenderBox child, _CellIndex slot) {
    renderObject.insertCell(child, slot);
  }

  @override
  void moveRenderObjectChild(RenderBox child, _CellIndex oldSlot, _CellIndex newSlot) {
    renderObject.moveCell(child, oldSlot, newSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, _CellIndex slot) {
    renderObject.removeCell(child, slot);
  }

  // ---- Walking the children ----

  @override
  void visitChildren(ElementVisitor visitor) {
    _children.values.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<Element> children = _children.values.toList()..sort(_compareChildren);
    return children.map((Element child) {
      return child.toDiagnosticsNode(name: child.slot.toString());
    }).toList();
  }

  int _compareChildren(Element a, Element b) {
    final _CellIndex aSlot = a.slot! as _CellIndex;
    final _CellIndex bSlot = b.slot! as _CellIndex;
    return aSlot.compareTo(bSlot);
  }

  // ---- _CellManager implementation ----

  // TODO: handle keys

  @override
  void buildCell(_CellIndex index) {
    owner!.buildScope(this, () {
      final Element? oldElement = _children[index];
      final Widget newWidget = _buildCell(index);
      final Element? newChild = updateChild(oldElement, newWidget, index);
      assert(newChild != null); // because newWidget is never null.
      _children[index] = newChild!;
    });
  }

  Widget _buildCell(_CellIndex index) {
    // TODO: catch errors.
    // Wrap this in a builder? For inheritedWidgets? What about keys?
    return widget.delegate.buildCell(this, index.column, index.row);
  }

  @override
  void removeCell(_CellIndex index) {
    assert(_children.containsKey(index));
    owner!.buildScope(this, () {
      final Element? newChild = updateChild(_children[index], null, /* slot ignored: */ null);
      assert(newChild == null);
      _children.remove(index);
    });
  }
}

class _RenderRawTableViewport extends RenderBox {
  _RenderRawTableViewport({
    required ViewportOffset horizontalOffset,
    required ViewportOffset verticalOffset,
    required RawTableDelegate delegate,
    required this.cellManager,
  }) : _horizontalOffset = horizontalOffset,
        _verticalOffset = verticalOffset,
        _delegate = delegate;

  ViewportOffset get horizontalOffset => _horizontalOffset;
  ViewportOffset _horizontalOffset;
  set horizontalOffset(ViewportOffset value) {
    if (_horizontalOffset == value) {
      return;
    }
    _horizontalOffset = value;
    markNeedsLayout();
  }

  ViewportOffset get verticalOffset => _verticalOffset;
  ViewportOffset _verticalOffset;
  set verticalOffset(ViewportOffset value) {
    if (_verticalOffset == value) {
      return;
    }
    _verticalOffset = value;
    markNeedsLayout();
  }

  RawTableDelegate get delegate => _delegate;
  RawTableDelegate _delegate;
  set delegate(RawTableDelegate value) {
    if (_delegate == value) {
      return;
    }
    _delegate = value;
    markNeedsLayout();
  }

  final _CellManager cellManager;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _horizontalOffset.addListener(markNeedsLayout);
    _verticalOffset.addListener(markNeedsLayout);
    for (final RenderBox child in _children.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    _horizontalOffset.removeListener(markNeedsLayout);
    _verticalOffset.removeListener(markNeedsLayout);
    for (final RenderBox child in _children.values) {
      child.detach();
    }
    super.detach();
  }

  @override
  void redepthChildren() {
    for (final RenderBox child in _children.values) {
      child.redepthChildren();
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.values.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return _children.keys.map<DiagnosticsNode>((_CellIndex index) {
      return _children[index]!.toDiagnosticsNode(name: index.toString());
    }).toList();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(() {
      if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
        throw FlutterError('Unbound constraints not allowed'); // TODO
      }
      return true;
    }());
    return constraints.biggest;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in _children.values) {
      final BoxParentData parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  final SplayTreeMap<_CellIndex, RenderBox> _children = SplayTreeMap<_CellIndex, RenderBox>();

  @override
  void performLayout() {
    // Ignoring return value since we are doing a layout either way.
    horizontalOffset.applyViewportDimension(size.width);
    verticalOffset.applyViewportDimension(size.height);

    // TODO: figure out in what cases we can skip recalculating this.
    // ---- Calculate the first visible column. ----
    int column = 0;
    double startOfColumn = 0.0;
    // If this is null there is no column with index `column`.
    double? columnWidth = _getColumnWidth(column);
    while (columnWidth != null && startOfColumn + columnWidth < horizontalOffset.pixels) {
      startOfColumn += columnWidth;
      column += 1;
      columnWidth = _getColumnWidth(column);
    }
    final double offsetIntoColumn = horizontalOffset.pixels - startOfColumn;
    final int firstColumn = column;
    // double? columnCorrection = columnWidth == null ? offsetIntoColumn : null;

    // ---- Calculate the first visible row. ----
    int row = 0;
    double startOfRow = 0.0;
    // If this is null there is no row with index `row`.
    double? rowHeight = _getRowHeight(row);
    while (rowHeight != null && startOfRow + rowHeight < verticalOffset.pixels) {
      startOfRow += rowHeight;
      row += 1;
      rowHeight = _getRowHeight(row);
    }
    final double offsetIntoRow = verticalOffset.pixels - startOfRow;
    final int firstRow = row;
    // double? rowCorrection = rowHeight == null ? offsetIntoRow : 0.0;
    //
    // if (rowCorrection != null || columnCorrection != null) {
    //   // TODO: This is missing viewport dimension & implement correction
    //   throw UnimplementedError('1 Scroll correction not implemented');
    // }

    // ---- Calculate last visible column ---
    double endOfColumn = startOfColumn;
    if (columnWidth != null) {
      final double lastVisibleColumnPixels = horizontalOffset.pixels + size.width;
      endOfColumn = startOfColumn + columnWidth;
      while (endOfColumn < lastVisibleColumnPixels) {
        columnWidth = _getColumnWidth(column + 1);
        if (columnWidth == null) {
          break;
        }
        column += 1;
        startOfColumn = endOfColumn;
        endOfColumn += columnWidth;
      }
    }
    final int lastColumn = column;
    // columnCorrection = columnWidth == null ? lastVisibleColumnPixels - startOfColumn: null;

    // ---- Calculate last visible row ---
    double endOfRow = startOfRow;
    if (rowHeight != null) {
      final double lastVisibleRowPixels = verticalOffset.pixels + size.height;
      endOfRow = startOfRow + rowHeight;
      while (endOfRow < lastVisibleRowPixels) {
        rowHeight = _getRowHeight(row + 1);
        if (rowHeight == null) {
          break;
        }
        row += 1;
        startOfRow = endOfRow;
        endOfRow += rowHeight;
      }
    }
    final int lastRow = row;
    // rowCorrection = rowHeight == null ? lastVisibleRowPixels - startOfRow: null;
    //
    // if (rowCorrection != null || columnCorrection != null) {
    //   // TODO: implement correction
    //   throw UnimplementedError('2 Scroll correction not implemented');
    // }

    // ---- layout columns, rows ----
    final Set<_CellIndex> _unusedIndices = HashSet<_CellIndex>.from(_children.keys);
    double yPaintOffset = -offsetIntoRow;
    for (int row = firstRow; row <= lastRow; row += 1) {
      double xPaintOffset = -offsetIntoColumn;
      final double rowHeight = _getRowHeight(row)!;
      for (int column = firstColumn; column <= lastColumn; column += 1) {
        final double columnWidth = _getColumnWidth(column)!;
        final _CellIndex index = _CellIndex(row: row, column: column);
        if (_needsRebuild || !_children.containsKey(index)) {
          invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
            cellManager.buildCell(index);
          });
        }

        assert(_children.containsKey(index));
        final RenderBox cell = _children[index]!;
        _unusedIndices.remove(index);
        final BoxConstraints cellConstraints = BoxConstraints.tightFor(
          width: columnWidth,
          height: rowHeight,
        );
        cell.layout(cellConstraints);

        final BoxParentData cellParentData = cell.parentData! as BoxParentData;
        cellParentData.offset = Offset(xPaintOffset, yPaintOffset);
        xPaintOffset += columnWidth;
      }
      yPaintOffset += rowHeight;
    }

    invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
      _unusedIndices.forEach(cellManager.removeCell);
    });
    _needsRebuild = false;

    // TODO: figure out in what cases we can skip recalculating this.
    // ---- calculate content dimensions ----
    if (delegate.columnCount != null) {
      double scrollExtent = endOfColumn;
      column += 1;
      while (column < delegate.columnCount!) {
        scrollExtent += _getColumnWidth(column)!;
        column += 1;
      }
      // TODO: Do something with return value?
      horizontalOffset.applyContentDimensions(0.0, math.max(0.0, scrollExtent - size.width));
    }
    if (delegate.rowCount != null) {
      double scrollExtent = endOfRow;
      row += 1;
      while (row < delegate.rowCount!) {
        scrollExtent += _getRowHeight(row)!;
        row += 1;
      }
      // TODO: Do something with return value?
      verticalOffset.applyContentDimensions(0.0, math.max(0.0, scrollExtent - size.height));
    }
  }

  double? _getColumnWidth(int column) {
    // TODO: caching & error handling.
    if (delegate.columnCount != null && column >= delegate.columnCount!) {
      return null;
    }
    return delegate.buildColumnSpec(column)?.calculateDimension(
      RawTableCellMetrics(viewportExtent: size.width),
    );
  }

  double? _getRowHeight(int row) {
    // TODO: caching & error handling.
    if (delegate.rowCount != null && row >= delegate.rowCount!) {
      return null;
    }
    return delegate.buildRowSpec(row)?.calculateDimension(
      RawTableCellMetrics(viewportExtent: size.height),
    );
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_children.isEmpty) {
      return;
    }
    // TODO: Only if we actually have overflow and clipping is enabled.
    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintContents,
      clipBehavior: Clip.hardEdge, // TODO: pass in
      oldLayer: _clipRectLayer.layer,
    );
  }

  void _paintContents(PaintingContext context, Offset offset) {
    for (final RenderBox child in _children.values) {
      final BoxParentData childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, offset + childParentData.offset);
    }
  }

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  // ---- called from Element ----

  bool _needsRebuild = true;
  void markNeedsLayoutWithRebuild() {
    _needsRebuild = true;
    markNeedsLayout();
  }

  void insertCell(RenderBox child, _CellIndex slot) {
    assert(_debugTrackOrphans(newOrphan: _children[slot]));
    _children[slot] = child;
    adoptChild(child);
  }

  void moveCell(RenderBox child, _CellIndex oldSlot, _CellIndex newSlot) {
    if (_children[oldSlot] == child) {
      _children.remove(oldSlot);
    }
    assert(_debugTrackOrphans(newOrphan: _children[newSlot], noLongerOrphan: child));
    _children[newSlot] = child;
  }

  void removeCell(RenderBox child, _CellIndex slot) {
    if (_children[slot] == child) {
      _children.remove(slot);
    }
    assert(_debugTrackOrphans(noLongerOrphan: child));
    dropChild(child);
  }

  List<RenderBox>? _debugOrphans;

  // When a child is inserted into a slot currently occupied by another child,
  // it becomes an orphan until it is either moved to another slot or removed.
  bool _debugTrackOrphans({RenderBox? newOrphan, RenderBox? noLongerOrphan}) {
    assert(() {
      _debugOrphans ??= <RenderBox>[];
      if (newOrphan != null) {
        _debugOrphans!.add(newOrphan);
      }
      if (noLongerOrphan != null) {
        _debugOrphans!.remove(noLongerOrphan);
      }
      return true;
    }());
    return true;
  }
}

// TODO: This probably will have to be a Listenable/ChangeNotifier.
abstract class RawTableDelegate {
  Widget buildCell(BuildContext context, int column, int row);

  int? get columnCount;
  int? get rowCount;

  RawTableDimensionSpec? buildColumnSpec(int column);
  RawTableDimensionSpec? buildRowSpec(int row);

  bool shouldRebuild(RawTableDelegate oldDelegate);
}

// TODO: better name. RawTableSpecDelegate ?
class RawTableCellMetrics {
  RawTableCellMetrics({required this.viewportExtent});

  final double viewportExtent;
}

abstract class RawTableDimensionSpec {
  const RawTableDimensionSpec();

  double calculateDimension(RawTableCellMetrics metrics);
}

class FixedRawTableDimensionSpec extends RawTableDimensionSpec {
  const FixedRawTableDimensionSpec(this.pixels) : assert(pixels >= 0.0);

  final double pixels;

  @override
  double calculateDimension(RawTableCellMetrics metrics) => pixels;
}

class ViewportFractionRawTableDimensionSpec extends RawTableDimensionSpec {
  const ViewportFractionRawTableDimensionSpec(this.fraction) : assert(fraction >= 0.0);

  final double fraction;

  @override
  double calculateDimension(RawTableCellMetrics metrics) => metrics.viewportExtent * fraction;
}

typedef RawTableSpecCombiner = double Function(double, double);

class CombingingRawTableDimensionSpec extends RawTableDimensionSpec {
  const CombingingRawTableDimensionSpec(this.spec1, this.spec2, this.combiner);

  final RawTableDimensionSpec spec1;
  final RawTableDimensionSpec spec2;
  final RawTableSpecCombiner combiner;

  @override
  double calculateDimension(RawTableCellMetrics metrics) => combiner(spec1.calculateDimension(metrics), spec2.calculateDimension(metrics));
}

class MaxTableDimensionSpec extends CombingingRawTableDimensionSpec {
  const MaxTableDimensionSpec(RawTableDimensionSpec spec1, RawTableDimensionSpec spec2) : super(spec1, spec2, math.max);
}

class MinTableDimensionSpec extends CombingingRawTableDimensionSpec {
  const MinTableDimensionSpec(RawTableDimensionSpec spec1, RawTableDimensionSpec spec2) : super(spec1, spec2, math.min);
}

@immutable
class _CellIndex implements Comparable<_CellIndex> {
  const _CellIndex({required this.row, required this.column, this.offset});

  final int row;
  final int column;
  final Offset? offset;

  @override
  bool operator ==(Object other) {
    return other is _CellIndex
        && other.row == row
        && other.column == column
        && other.offset == offset;
  }

  @override
  int get hashCode => hashValues(row, column, offset);

  @override
  int compareTo(_CellIndex other) {
    if (row == other.row) {
      if (column == other.column && offset != null) {
        if (offset!.dy == other.offset!.dy) {
          return offset!.dx.compareTo(other.offset!.dx);
        }
        return offset!.dy.compareTo(other.offset!.dy);
      }
      return column - other.column;
    }
    return row - other.row;
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, '_CellIndex')}(c: $column, r: $row${offset == null ? '' : ', $offset'})';
  }
}

abstract class _CellManager {
  void buildCell(_CellIndex index);
  void removeCell(_CellIndex index);
}
