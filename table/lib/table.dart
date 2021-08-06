import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Scrollbar;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'band.dart';
import 'border.dart';
import 'fake_viewport.dart';

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
    // TODO: deal with panning
    return Scrollbar( // TODO: remove this when MaterialScrollBehavior auto-adds scrollbars on horizontal scrollers
      controller: horizontalController,
      isAlwaysShown: true,
      child:  Scrollable(
        controller: horizontalController,
        axisDirection: AxisDirection.right, // TODO: make these configurable
        viewportBuilder: (BuildContext context, ViewportOffset horizontalOffset) {
          return FakeViewport( // This is only here to increase depth of ScrollNotification
            child: Scrollable(
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
            ),
            );
          },
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

  // @override
  // void update(_RawTableViewport newWidget) {
  //   // Rebuild if the delegate requires it. (Rebuild will delegate to layout).
  //   final _RawTableViewport oldWidget = widget;
  //   super.update(newWidget);
  //   final RawTableDelegate newDelegate = newWidget.delegate;
  //   final RawTableDelegate oldDelegate = oldWidget.delegate;
  //   if (newDelegate != oldDelegate && (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate))) {
  //     rebuild(); // ultimately runs performRebuild()
  //     // renderObject.markNeedsLayoutWithRebuild(); // rebuild(); // TODO: or performRebuild? or remove performRebuild impl alltogether and just mark renderobject?
  //   }
  // }

  // TODO: check inheritedwidgets.
  @override
  void performRebuild() {
    super.performRebuild();
    // Children list is updated during layout since we only know during layout
    // which children will be visible.
    renderObject.markNeedsLayout(withCellRebuild: true, withSpecRebuild: true);
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
      _delegate.removeListener(_handleDelegateNotification);
    }
    final RawTableDelegate oldDelegate = value;
    _delegate = value;
    if (attached) {
      _delegate.addListener(_handleDelegateNotification);
    }
    if (_delegate.runtimeType != oldDelegate.runtimeType || _delegate.shouldRebuild(oldDelegate)) {
      _handleDelegateNotification();
    }
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

  void _handleDelegateNotification() => markNeedsLayout(withCellRebuild: true, withSpecRebuild: true);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RawTableViewportParentData) {
      child.parentData = _RawTableViewportParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _horizontalOffset.addListener(markNeedsLayout);
    _verticalOffset.addListener(markNeedsLayout);
    _delegate.addListener(_handleDelegateNotification);
    for (final RenderBox child in _children.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    _horizontalOffset.removeListener(markNeedsLayout);
    _verticalOffset.removeListener(markNeedsLayout);
    _delegate.removeListener(_handleDelegateNotification);
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
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    if (size.contains(position)) {
      bool isHit = hitTestChildren(result, position: position);
      // TODO: Maybe make the row/column hit test order configurable?
      isHit = _hitTestRows(result, position: position) || isHit;
      isHit = _hitTestColumns(result, position: position) || isHit;
      assert(hitTestSelf(position) == false); // no need to call this.
      if (isHit) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
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
          // TODO: add cell
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  bool _hitTestRows(BoxHitTestResult result, {required Offset position}) {
    final double left = math.max(0.0, _columnMetrics[_firstVisibleCell!.column]!.start - _horizontalOffset.pixels);
    final double right = _columnMetrics[_lastVisibleCell!.column]!.end - _horizontalOffset.pixels;
    for (int row = _firstVisibleCell!.row; row <= _lastVisibleCell!.row; row++) {
      final _Band band = _rowMetrics[row]!;
      final double top = math.max(0.0, band.start - _verticalOffset.pixels);
      final double bottom = band.end - _verticalOffset.pixels;
      final Rect rowRect = Rect.fromLTRB(left, top, right, bottom);
      if (rowRect.contains(position)) {
        return result.addWithPaintOffset(
          offset: rowRect.topLeft,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(position - rowRect.topLeft == transformed);
            result.add(HitTestEntry(band));
            return true;
          },
        );
      }
    }
    return false;
  }

  bool _hitTestColumns(BoxHitTestResult result, {required Offset position}) {
    final double top = math.max(0.0, _rowMetrics[_firstVisibleCell!.row]!.start - _verticalOffset.pixels);
    final double bottom = _rowMetrics[_lastVisibleCell!.row]!.end - _verticalOffset.pixels;
    for (int column = _firstVisibleCell!.column; column <= _lastVisibleCell!.column; column++) {
      final _Band band = _columnMetrics[column]!;
      final double left = math.max(0.0, band.start - _horizontalOffset.pixels);
      final double right = band.end - _horizontalOffset.pixels;
      final Rect columnRect = Rect.fromLTRB(left, top, right, bottom);
      if (columnRect.contains(position)) {
        return result.addWithPaintOffset(
          offset: columnRect.topLeft,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(position - columnRect.topLeft == transformed);
            result.add(HitTestEntry(band));
            return true;
          },
        );
      }
    }
    return false;
  }

  final Map<_CellIndex, RenderBox> _children = <_CellIndex, RenderBox>{};

  @override
  void performResize() {
    final Size? oldSize = hasSize ? size : null;
    super.performResize();
    // Ignoring return value since we are doing a layout either way (performLayout will be invoked next).
    horizontalOffset.applyViewportDimension(size.width);
    verticalOffset.applyViewportDimension(size.height);
    if (oldSize != size) {
      // Specs can depend on viewport size.
      _needsSpecExtentUpdate = true;
    }
  }

  // Table metrics
  Map<int, _Band> _columnMetrics = <int, _Band>{};
  Map<int, _Band> _rowMetrics = <int, _Band>{};
  _CellIndex? _firstVisibleCell;
  _CellIndex? _lastVisibleCell;

  void _updateMetrics() {
    assert(_needsSpecRebuild || _needsSpecExtentUpdate);
    int? firstColumn;
    int? lastColumn;
    double startOfColumn = 0;
    final Map<int, _Band> newColumnMetrics = <int, _Band>{};
    // TODO: consider columnCount == null
    for (int column = 0; column < delegate.columnCount!; column++) {
      _Band? band = _columnMetrics.remove(column);
      assert(_needsSpecRebuild || band != null);
      final RawTableBand? bandSpec = _needsSpecRebuild ? delegate.buildColumnSpec(column) : band!.spec;
      if (bandSpec == null) {
        // TODO
        return;
      }
      band ??= _Band();
      band.update(
        spec: bandSpec,
        start: startOfColumn,
        extent: bandSpec.extent.calculateExtent(RawTableBandExtentDelegate(
          viewportExtent: size.width,
          precedingExtent: startOfColumn,
        )),
      );
      newColumnMetrics[column] = band;
      final double endOfColumn = startOfColumn + band.extent;
      if (endOfColumn >= horizontalOffset.pixels && firstColumn == null) {
        firstColumn = column;
      }
      if (endOfColumn >= horizontalOffset.pixels + size.width && lastColumn == null) {
        lastColumn = column;
      }

      startOfColumn = endOfColumn;
    }
    for (final _Band band in _columnMetrics.values) {
      band.dispose();
    }
    _columnMetrics = newColumnMetrics;
    if (firstColumn == null && _columnMetrics.isNotEmpty) {
      // TODO: we are scrolled too far.
    }
    if (lastColumn == null) {
      // TODO: its okay if rows can't fill whole viewport, if they could: correction
      lastColumn = _columnMetrics.length - 1;
    }

    int? firstRow;
    int? lastRow;
    double startOfRow = 0;
    final Map<int, _Band> newRowMetrics = <int, _Band>{};
    // TODO: consider rowCount == null
    for (int row = 0; row < delegate.rowCount!; row++) {
      _Band? band = _rowMetrics.remove(row);
      assert(_needsSpecRebuild || band != null);
      final RawTableBand? bandSpec = _needsSpecRebuild ? delegate.buildRowSpec(row) : band!.spec;
      if (bandSpec == null) {
        // TODO
        return;
      }
      band ??= _Band();
      band.update(
        spec: bandSpec,
        start: startOfRow,
        extent: bandSpec.extent.calculateExtent(RawTableBandExtentDelegate(
          viewportExtent: size.height,
          precedingExtent: startOfRow,
        )),
      );
      newRowMetrics[row] = band;
      final double endOfRow = startOfRow + band.extent;
      if (endOfRow >= verticalOffset.pixels && firstRow == null) {
        firstRow = row;
      }
      if (endOfRow >= verticalOffset.pixels + size.height && lastRow == null) {
        lastRow = row;
      }

      startOfRow = endOfRow;
    }
    for (final _Band band in _rowMetrics.values) {
      band.dispose();
    }
    _rowMetrics = newRowMetrics;
    if (firstRow == null && _rowMetrics.isNotEmpty) {
      // TODO: we are scrolled too far.
    }
    if (lastRow == null) {
      // TODO: its okay if rows can't fill whole viewport, if they could: correction
      lastRow = _rowMetrics.length - 1;
    }
    assert(firstRow != null);
    assert(lastRow != null);
    assert(firstColumn != null);
    assert(lastColumn != null);
    _firstVisibleCell = _CellIndex(row: firstRow!, column: firstColumn!);
    _lastVisibleCell = _CellIndex(row: lastRow, column: lastColumn);

    // ---- update content dimensions ----
    final _Band lastAvailableRow = _rowMetrics[_rowMetrics.length - 1]!;
    final double endOfLastAvailableRow = lastAvailableRow.start + lastAvailableRow.extent;
    final _Band lastAvailableColumn = _columnMetrics[_columnMetrics.length - 1]!;
    final double endOfLastAvailableColumn = lastAvailableColumn.start + lastAvailableColumn.extent;
    // TODO: Do something with return values
    horizontalOffset.applyContentDimensions(0.0, math.max(0.0, endOfLastAvailableColumn - size.width));
    verticalOffset.applyContentDimensions(0.0, math.max(0.0, endOfLastAvailableRow - size.height));

    _needsSpecRebuild = false;
    _needsSpecExtentUpdate = false;
  }

  @override
  void performLayout() {
    if (_needsSpecRebuild || _needsSpecExtentUpdate) {
      _updateMetrics();
    } else {
      int? firstColumn;
      int? lastColumn;
      final double lastVisibleColumnPixel = horizontalOffset.pixels + size.width;
      for (int column = 0; column < _columnMetrics.length; column++) {
        final double endOfColumn = _columnMetrics[column]!.end;
        if (endOfColumn >= horizontalOffset.pixels && firstColumn == null) {
          firstColumn = column;
        }
        if (endOfColumn >= lastVisibleColumnPixel && lastColumn == null) {
          lastColumn = column;
          break;
        }
      }
      if (firstColumn == null && _columnMetrics.isNotEmpty) {
        // TODO: we are scrolled too far.
      }
      if (lastColumn == null) {
        // TODO: its okay if rows can't fill whole viewport, if they could: correction
        lastColumn = _columnMetrics.length - 1;
      }

      int? firstRow;
      int? lastRow;
      final double lastVisibleRowPixel = verticalOffset.pixels + size.height;
      for (int row = 0; row < _rowMetrics.length; row++) {
        final double endOfRow = _rowMetrics[row]!.end;
        if (endOfRow >= verticalOffset.pixels && firstRow == null) {
          firstRow = row;
        }
        if (endOfRow >= lastVisibleRowPixel && lastRow == null) {
          lastRow = row;
          break;
        }
      }
      if (firstRow == null && _rowMetrics.isNotEmpty) {
        // TODO: we are scrolled too far.
      }
      if (lastRow == null) {
        // TODO: its okay if rows can't fill whole viewport, if they could: correction
        lastRow = _rowMetrics.length - 1;
      }

      _firstVisibleCell = _CellIndex(row: firstRow!, column: firstColumn!);
      _lastVisibleCell = _CellIndex(row: lastRow, column: lastColumn);
    }

    final _CellIndex firstCell = _firstVisibleCell!;
    final _CellIndex lastCell = _lastVisibleCell!;
    final double offsetIntoColumn = horizontalOffset.pixels - _columnMetrics[firstCell.column]!.start;
    final double offsetIntoRow = verticalOffset.pixels - _rowMetrics[firstCell.row]!.start;

    // ---- layout columns, rows ----
    cellManager.startLayout();
    double yPaintOffset = -offsetIntoRow;
    RenderBox? previousCell;
    for (int row = firstCell.row; row <= lastCell.row; row += 1) {
      double xPaintOffset = -offsetIntoColumn;
      final _Band rowMetric = _rowMetrics[row]!;
      final double rowHeight = rowMetric.extent;
      for (int column = firstCell.column; column <= lastCell.column; column += 1) {
        final double columnWidth = _columnMetrics[column]!.extent;
        final _CellIndex index = _CellIndex(row: row, column: column);
        if (_needsCellRebuild || !_children.containsKey(index)) {
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

        _parentDataOf(cell)
          ..offset = Offset(xPaintOffset, yPaintOffset)
          ..previousSibling = previousCell
          ..nextSibling = null
          ..index = index;
        if (previousCell != null) {
          _parentDataOf(previousCell).nextSibling = cell;
        }

        xPaintOffset += columnWidth;
        previousCell = cell;
      }
      yPaintOffset += rowHeight;
    }

    invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
      cellManager.endLayout();
    });
    _needsCellRebuild = false;
    assert(_debugOrphans?.isEmpty ?? true);
    // TODO: assert that all children are linked
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

  _RawTableViewportParentData _parentDataOf(RenderBox child) {
    return child.parentData! as _RawTableViewportParentData;
  }

  RenderBox? _cellAfter(RenderBox child) {
    return _parentDataOf(child).nextSibling;
  }

  RenderBox? _cellBefore(RenderBox child) {
    return _parentDataOf(child).previousSibling;
  }

  Offset _paintOffsetOf(RenderBox child) {
    return _parentDataOf(child).offset;
  }

  Offset _paintEndOffsetOf(RenderBox child) {
    final BoxParentData childParentData = _parentDataOf(child);
    return Offset(childParentData.offset.dx + child.size.width, childParentData.offset.dy + child.size.height);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    final List<double> _rowOffsets = <double>[];
    final List<double> _columnOffsets = <double>[];
    int lastColumn = -1;
    int lastRow = - 1;

    for (RenderBox? cell = _children[_firstVisibleCell]; cell != null; cell = _cellAfter(cell)) {
      final _RawTableViewportParentData parentData = _parentDataOf(cell);
      context.paintChild(cell, offset + parentData.offset);
      if (parentData.index.column > lastColumn && parentData.index.column != 0) {
        _columnOffsets.add(parentData.offset.dx + offset.dx);
        lastColumn = parentData.index.column;
      }
      if (parentData.index.row > lastRow && parentData.index.row != 0) {
        _rowOffsets.add(parentData.offset.dy + offset.dy);
        lastRow = parentData.index.row;
      }
    }
    final Offset lastChild = _paintEndOffsetOf(_children[_lastVisibleCell]!);
    if (_lastVisibleCell!.row != _rowMetrics.length - 1) {
      _rowOffsets.add(lastChild.dy + offset.dy);
    }
    if (_lastVisibleCell!.column != _columnMetrics.length - 1) {
      _columnOffsets.add(lastChild.dx + offset.dx);
    }

    if (border != null && _children.isNotEmpty) {
      final Offset firstVisibleOffset = _paintOffsetOf(_children[_firstVisibleCell]!) + offset;
      final Offset lastVisibleOffset = _paintEndOffsetOf(_children[_lastVisibleCell]!) + offset;
      final Rect drawnRect = Rect.fromPoints(firstVisibleOffset, lastVisibleOffset);
      final Rect visibleRect = (offset & size).intersect(drawnRect);

      final Rect outerOffsets = Rect.fromLTRB(
        _firstVisibleCell!.column == 0 ? drawnRect.left : double.nan,
        _firstVisibleCell!.row == 0 ? drawnRect.top : double.nan,
        _lastVisibleCell!.column == _columnMetrics.length - 1 ? drawnRect.right : double.nan,
        _lastVisibleCell!.row == _rowMetrics.length - 1 ? drawnRect.bottom : double.nan,
      );

      border!.paint(context.canvas, visibleRect, _rowOffsets, _columnOffsets, outerOffsets);
    }
  }

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  bool _needsCellRebuild = true;
  bool _needsSpecRebuild = true;
  bool _needsSpecExtentUpdate = false;

  @override
  void markNeedsLayout({bool withCellRebuild = false, bool withSpecRebuild = false}) {
    _needsCellRebuild = _needsCellRebuild || withCellRebuild;
    _needsSpecRebuild = _needsSpecRebuild || withSpecRebuild;
    // TODO: set _needsDimensionUpdate if we depend on size of children.
    super.markNeedsLayout();
  }

  // ---- called from Element ----

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

  static const _CellIndex invalid = _CellIndex(row: -1, column: -1);

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

class _Band with Diagnosticable implements HitTestTarget, MouseTrackerAnnotation  {
  double get start => _start;
  late double _start;

  double get extent => _extent;
  late double _extent;

  RawTableBand get spec => _spec!;
  RawTableBand? _spec;

  double get end => start + extent;

  // ---- Band Management ----

  void update({required RawTableBand spec, required double start, required double extent}) {
    _start = start;
    _extent = extent;
    if (spec == _spec) {
      return;
    }
    _spec = spec;
    // Only sync recognizers if they are in use already.
    if (_recognizers != null) {
      _syncRecognizers();
    }
  }

  void dispose() {
    _disposeRecognizers();
  }

  // ---- Recognizers management ----

  Map<Type, GestureRecognizer>? _recognizers;

  void _syncRecognizers() {
    if (spec.recognizerFactories.isEmpty) {
      _disposeRecognizers();
      return;
    }
    final Map<Type, GestureRecognizer> newRecognizers = <Type, GestureRecognizer>{};
    for (final Type type in spec.recognizerFactories.keys) {
      assert(!newRecognizers.containsKey(type));
      newRecognizers[type] = _recognizers?.remove(type) ?? spec.recognizerFactories[type]!.constructor();
      assert(newRecognizers[type].runtimeType == type, 'GestureRecognizerFactory of type $type created a GestureRecognizer of type ${newRecognizers[type].runtimeType}. The GestureRecognizerFactory must be specialized with the type of the class that it returns from its constructor method.');
      spec.recognizerFactories[type]!.initializer(newRecognizers[type]!);
    }
    _disposeRecognizers(); // only disposes the ones that where not re-used above.
    _recognizers = newRecognizers;
  }

  void _disposeRecognizers() {
    if (_recognizers != null) {
      for (final GestureRecognizer recognizer in _recognizers!.values) {
        recognizer.dispose();
      }
      _recognizers = null;
    }
  }

  // ---- HitTestTarget ----

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent && spec.recognizerFactories.isNotEmpty) {
      if (_recognizers == null) {
        _syncRecognizers();
      }
      assert(_recognizers != null);
      for (final GestureRecognizer recognizer in _recognizers!.values) {
        recognizer.addPointer(event);
      }
    }
  }

  // ---- MouseTrackerAnnotation ----

  @override
  MouseCursor get cursor => spec.cursor;

  @override
  PointerEnterEventListener? get onEnter => spec.onEnter;

  @override
  PointerExitEventListener? get onExit => spec.onExit;

  @override
  bool get validForMouseTracker => true;
}

class _RawTableViewportParentData extends BoxParentData {
  RenderBox? nextSibling;
  RenderBox? previousSibling;
  _CellIndex index = _CellIndex.invalid;
}
