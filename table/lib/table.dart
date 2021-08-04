import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:table/table_band.dart';

import 'border.dart';

class RawTableScrollView extends StatefulWidget {
  const RawTableScrollView({Key? key, this.horizontalController, this.verticalController, this.border, required this.delegate}) : super(key: key);

  final ScrollController? horizontalController;
  final ScrollController? verticalController;
  final RawTableBorder? border;

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
                  border: widget.border,
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
    this.border,
  }) : super(key: key);

  final ViewportOffset horizontalOffset;
  final ViewportOffset verticalOffset;
  final RawTableDelegate delegate;
  final RawTableBorder? border;

  @override
  RenderObjectElement createElement() => _RawTableViewportElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRawTableViewport(
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      delegate: delegate,
      cellManager: context as _RawTableViewportElement,
      border: border,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderRawTableViewport renderObject) {
    assert(identical(context, renderObject.cellManager));
    renderObject
      ..horizontalOffset = horizontalOffset
      ..verticalOffset = verticalOffset
      ..delegate = delegate
      ..border = border;
  }
}

class _RawTableViewportElement extends RenderObjectElement implements _CellManager {
  _RawTableViewportElement(_RawTableViewport widget) : super(widget);

  // ---- Specializing the getters ----

  @override
  _RawTableViewport get widget => super.widget as _RawTableViewport;

  @override
  _RenderRawTableViewport get renderObject => super.renderObject as _RenderRawTableViewport;

  Map<_CellIndex, Element> _indexToChild = <_CellIndex, Element>{}; // contains all children, incl. keyed.
  Map<Key, Element> _keyToChild = <Key, Element>{};
  // Used between startLayout() & endLayout() to compute the new values for _indexToChild and _keyToChild.
  Map<_CellIndex, Element>? _newIndexToChild;
  Map<Key, Element>? _newKeyToChild;

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
    assert(!_debugIsDoingLayout);
    super.forgetChild(child);
    _indexToChild.remove(child.slot);
    if (child.widget.key != null) {
      _keyToChild.remove(child.widget.key);
    }
  }

  // ---- Maintaining the render object tree ----

  @override
  void insertRenderObjectChild(RenderBox child, _CellIndex slot) {
    renderObject.insertCell(child, slot);
  }

  @override
  void moveRenderObjectChild(RenderBox child, _CellIndex oldSlot, _CellIndex newSlot) {
    renderObject.moveCell(child, from: oldSlot, to: newSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, _CellIndex slot) {
    renderObject.removeCell(child, slot);
  }

  // ---- Walking the children ----

  @override
  void visitChildren(ElementVisitor visitor) {
    _indexToChild.values.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<Element> children = _indexToChild.values.toList()..sort(_compareChildren);
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

  bool get _debugIsDoingLayout => _newKeyToChild != null && _newIndexToChild != null;

  @override
  void startLayout() {
    assert(!_debugIsDoingLayout);
    _newIndexToChild = <_CellIndex, Element>{};
    _newKeyToChild = <Key, Element>{};
  }

  @override
  void buildCell(_CellIndex index) {
    assert(_debugIsDoingLayout);
    owner!.buildScope(this, () {
      final Widget newWidget = _buildCell(index);
      final Element? oldElement = _retrieveOldElement(newWidget, index);
      final Element? newChild = updateChild(oldElement, newWidget, index);
      assert(newChild != null); // because newWidget is never null.
      _newIndexToChild![index] = newChild!;
      if (newWidget.key != null) {
        _newKeyToChild![newWidget.key!] = newChild;
      }

      // oldElement == null && newWidget != null -> insertRenderObject
      // oldElement != null && newWidget == null -> removeRenderObject
      // oldElement != null && newWidget != null -> if update possible: moveRenderObject, else removeRenderObject & insertRenderObject
    });
  }

  Element? _retrieveOldElement(Widget newWidget, _CellIndex index) {
    if (newWidget.key != null) {
      final Element? result = _keyToChild.remove(newWidget.key);
      if (result != null) {
        _indexToChild.remove(result.slot);
      }
      return result;
    }
    final Element? potentialOldElement = _indexToChild[index];
    if (potentialOldElement != null && potentialOldElement.widget.key == null) {
      return _indexToChild.remove(index);
    }
    return null;
  }

  Widget _buildCell(_CellIndex index) {
    // TODO: catch errors.
    // Wrap this in a builder? For inheritedWidgets? What about keys?
    return widget.delegate.buildCell(this, index.column, index.row);
  }

  @override
  void reuseCell(_CellIndex index) {
    assert(_debugIsDoingLayout);
    final Element? elementToReuse = _indexToChild.remove(index);
    assert(elementToReuse != null); // has to exist since we are reusing it.
    _newIndexToChild![index] = elementToReuse!;
    if (elementToReuse.widget.key != null) {
      assert(_keyToChild.containsKey(elementToReuse.widget.key));
      assert(_keyToChild[elementToReuse.widget.key] == elementToReuse);
      _newKeyToChild![elementToReuse.widget.key!] = _keyToChild.remove(elementToReuse.widget.key)!;
    }
  }

  @override
  void endLayout() {
    assert(_debugIsDoingLayout);

    // Unmount all elements that have not been reused in the layout cycle.
    for (final Element element in _indexToChild.values) {
      if (element.widget.key == null) {
        // If it has a key, we handle it below.
        updateChild(element, null, null);
      } else {
        assert(_keyToChild.containsValue(element));
      }
    }
    for (final Element element in _keyToChild.values) {
      assert(element.widget.key != null);
      updateChild(element, null, null);
    }

    _indexToChild = _newIndexToChild!;
    _keyToChild = _newKeyToChild!;
    _newIndexToChild = null;
    _newKeyToChild = null;
    assert(!_debugIsDoingLayout);
  }
}

class _RenderRawTableViewport extends RenderBox {
  _RenderRawTableViewport({
    required ViewportOffset horizontalOffset,
    required ViewportOffset verticalOffset,
    required RawTableDelegate delegate,
    required this.cellManager,
    RawTableBorder? border,
  }) : _horizontalOffset = horizontalOffset,
        _verticalOffset = verticalOffset,
        _delegate = delegate,
        _border = border;

  ViewportOffset get horizontalOffset => _horizontalOffset;
  ViewportOffset _horizontalOffset;
  set horizontalOffset(ViewportOffset value) {
    if (_horizontalOffset == value) {
      return;
    }
    if (attached) {
      _horizontalOffset.removeListener(markNeedsLayout);
    }
    _horizontalOffset = value;
    if (attached) {
      _horizontalOffset.addListener(markNeedsLayout);
    }
    markNeedsLayout();
  }

  ViewportOffset get verticalOffset => _verticalOffset;
  ViewportOffset _verticalOffset;
  set verticalOffset(ViewportOffset value) {
    if (_verticalOffset == value) {
      return;
    }
    if (attached) {
      _verticalOffset.removeListener(markNeedsLayout);
    }
    _verticalOffset = value;
    if (attached) {
      _verticalOffset.addListener(markNeedsLayout);
    }
    markNeedsLayout();
  }

  RawTableDelegate get delegate => _delegate;
  RawTableDelegate _delegate;
  set delegate(RawTableDelegate value) {
    if (_delegate == value) {
      return;
    }
    if (attached) {
      _delegate.removeListener(markNeedsLayoutWithRebuild);
    }
    _delegate = value;
    if (attached) {
      _delegate.addListener(markNeedsLayoutWithRebuild);
    }
    markNeedsLayout();
  }

  RawTableBorder? get border => _border;
  RawTableBorder? _border;
  set border(RawTableBorder? value) {
    if (_border == value) {
      return;
    }
    _border = value;
    markNeedsPaint();
  }

  final _CellManager cellManager;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _horizontalOffset.addListener(markNeedsLayout);
    _verticalOffset.addListener(markNeedsLayout);
    _delegate.addListener(markNeedsLayoutWithRebuild);
    for (final RenderBox child in _children.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    _horizontalOffset.removeListener(markNeedsLayout);
    _verticalOffset.removeListener(markNeedsLayout);
    _delegate.removeListener(markNeedsLayoutWithRebuild);
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
  void performResize() {
    super.performResize();
    // Ignoring return value since we are doing a layout either way (performLayout will be invoked next).
    horizontalOffset.applyViewportDimension(size.width);
    verticalOffset.applyViewportDimension(size.height);
  }

  @override
  void performLayout() {
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
    cellManager.startLayout();
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
        } else {
          cellManager.reuseCell(index);
        }

        assert(_children.containsKey(index));
        final RenderBox cell = _children[index]!;
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
      cellManager.endLayout();
    });
    _needsRebuild = false;
    _debugOrphans?.forEach(print);
    assert(_debugOrphans?.isEmpty ?? true);

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
    return delegate.buildColumnSpec(column)?.extent.calculateExtent(
      RawTableBandExtentDelegate(viewportExtent: size.width),
    );
  }

  double? _getRowHeight(int row) {
    // TODO: caching & error handling.
    if (delegate.rowCount != null && row >= delegate.rowCount!) {
      return null;
    }
    return delegate.buildRowSpec(row)?.extent.calculateExtent(
      RawTableBandExtentDelegate(viewportExtent: size.width),
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
    final Set<double> _rowOffsets = <double>{};
    final Set<double> _columnOffsets = <double>{};


    for (final RenderBox child in _children.values) {
      final BoxParentData childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, offset + childParentData.offset);
    }
    if (border != null) {
      // TODO: table could be smaller then size
      // final Iterable<double> rows = _rowTops.getRange(1, _rowTops.length - 1);
      // final Iterable<double> columns = _columnLefts!.skip(1);

      double? firstColumn;
      double? firstRow;
      double? lastColumn;
      double? lastRow;
      for (final _CellIndex index in _children.keys) {
        final BoxParentData childParentData = _children[index]!.parentData! as BoxParentData;
        if (index.column != 0) {
          _columnOffsets.add(offset.dx + childParentData.offset.dx);
          if (index.column == (delegate.columnCount! - 1)) {
            lastColumn = offset.dx + childParentData.offset.dx + _children[index]!.size.width;
          }
        } else {
          firstColumn = offset.dx + childParentData.offset.dx;
        }
        if (index.row != 0) {
          _rowOffsets.add(offset.dy + childParentData.offset.dy);
          if (index.row == (delegate.rowCount! - 1)) {
            lastRow = offset.dy + childParentData.offset.dy + _children[index]!.size.height;
          }
        } else {
          firstRow = offset.dy + childParentData.offset.dy;
        }
      }
      final Rect visibleTableRect = Rect.fromLTWH(firstColumn ?? 0, firstRow ?? 0, size.width - (firstColumn ?? 0), size.height - (firstRow ?? 0));
      border!.paint(context.canvas, visibleTableRect, _rowOffsets, _columnOffsets, Rect.fromLTRB(firstColumn ?? double.nan, firstRow ?? double.nan, lastColumn ?? double.nan, lastRow ?? double.nan));
      // border!.paint(context.canvas, size, _rowToStartOffset, _columnToStartOffset);
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

  void moveCell(RenderBox child, {required _CellIndex from, required _CellIndex to}) {
    if (_children[from] == child) {
      _children.remove(from);
    }
    assert(_debugTrackOrphans(newOrphan: _children[to], noLongerOrphan: child));
    _children[to] = child;
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

// TODO: Do we need more fine-grained control instead of just a blanked notifyListeners that rebuilds everything?
// Maybe `requestRebuild` for changes to buildCell/buildPrototype.
//   `requestLayout` for size changes, `request paint` for visuals.
abstract class RawTableDelegate extends ChangeNotifier {
  Widget buildCell(BuildContext context, int column, int row);

  int? get columnCount;
  int? get rowCount;

  RawTableBand? buildColumnSpec(int column);
  RawTableBand? buildRowSpec(int row);

  bool shouldRebuild(RawTableDelegate oldDelegate);
}

@immutable
class _CellIndex implements Comparable<_CellIndex> {
  const _CellIndex({required this.row, required this.column});

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    return other is _CellIndex
        && other.row == row
        && other.column == column;
  }

  @override
  int get hashCode => hashValues(row, column);

  @override
  int compareTo(_CellIndex other) {
    if (row == other.row) {
      return column - other.column;
    }
    return row - other.row;
  }

  @override
  String toString() {
    return '(column: $column, row: $row)';
  }
}

abstract class _CellManager {
  void startLayout();
  void buildCell(_CellIndex index);
  void reuseCell(_CellIndex index);
  void endLayout();
}
