import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Scrollbar;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:table/band_decoration.dart';

import 'band.dart';
import 'fake_viewport.dart';

class RawTableScrollView extends StatefulWidget {
  const RawTableScrollView({
    Key? key,
    this.horizontalController,
    this.verticalController,
    required this.delegate,
  }) : super(key: key);

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
  }) : _horizontalOffset = horizontalOffset,
        _verticalOffset = verticalOffset,
        _delegate = delegate;

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
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in _children.values) {
      final _RawTableViewportParentData parentData = _parentDataOf(child);
      final Rect childRect = parentData.offset & child.size;
      if (childRect.contains(position)) {
        // TODO: Do something with return value? Only add Row/Column if child is hit?
        result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - parentData.offset);
            return child.hitTest(result, position: transformed);
          },
        );
        // TODO: make it configurable in which order row/columns are hit?
        result.add(HitTestEntry(_rowMetrics[parentData.index.row]!));
        result.add(HitTestEntry(_columnMetrics[parentData.index.column]!));
        return true;
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
  int? _firstVisibleRow;
  int? _firstVisibleColumn;
  int? _lastVisibleRow;
  int? _lastVisibleColumn;

  int? get _lastStickyRow => delegate.numberOfStickyRows > 0 ? delegate.numberOfStickyRows - 1 : null;
  int? get _lastStickyColumn => delegate.numberOfStickyColumns > 0 ? delegate.numberOfStickyColumns - 1 : null;

  _CellIndex? get _firstVisibleCell {
    if (_firstVisibleRow == null || _firstVisibleColumn == null) {
      return null;
    }
    return _CellIndex(row: _firstVisibleRow!, column: _firstVisibleColumn!);
  }

  _CellIndex? get _lastVisibleCell {
    if (_lastVisibleRow == null || _lastVisibleColumn == null) {
      return null;
    }
    return _CellIndex(row: _lastVisibleRow!, column: _lastVisibleColumn!);
  }

  void _updateMetrics() {
    assert(_needsSpecRebuild || _needsSpecExtentUpdate);

    _firstVisibleColumn = null;
    _lastVisibleColumn = null;
    double startOfColumn = 0;
    double startOfStickyColumn = 0;
    final Map<int, _Band> newColumnMetrics = <int, _Band>{};
    for (int column = 0; column < delegate.numberOfColumns; column++) {
      final bool isSticky = column < delegate.numberOfStickyColumns;
      _Band? band = _columnMetrics.remove(column);
      assert(_needsSpecRebuild || band != null);
      final RawTableBand bandSpec = _needsSpecRebuild ? delegate.buildColumnSpec(column) : band!.spec;
      band ??= _Band();
      band.update(
        isSticky: isSticky,
        spec: bandSpec,
        start: isSticky ? startOfStickyColumn : startOfColumn,
        extent: bandSpec.extent.calculateExtent(RawTableBandExtentDelegate(
          viewportExtent: size.width,
          precedingExtent: isSticky ? startOfStickyColumn : startOfColumn,
        )),
      );
      newColumnMetrics[column] = band;
      if (!isSticky) {
        final double endOfColumn = startOfColumn + band.extent;
        if (endOfColumn >= horizontalOffset.pixels && _firstVisibleColumn == null) {
          _firstVisibleColumn = column;
        }
        if (endOfColumn >= horizontalOffset.pixels + size.width - startOfStickyColumn && _lastVisibleColumn == null) {
          _lastVisibleColumn = column;
        }
        startOfColumn = endOfColumn;
      } else {
        startOfStickyColumn = startOfStickyColumn + band.extent;
      }
    }
    assert(newColumnMetrics.length >= delegate.numberOfStickyColumns);
    for (final _Band band in _columnMetrics.values) {
      band.dispose();
    }
    _columnMetrics = newColumnMetrics;

    _firstVisibleRow = null;
    _lastVisibleRow = null;
    double startOfRow = 0;
    double startOfStickyRow = 0;
    final Map<int, _Band> newRowMetrics = <int, _Band>{};
    for (int row = 0; row < delegate.numberOfRows; row++) {
      final bool isSticky = row < delegate.numberOfStickyRows;
      _Band? band = _rowMetrics.remove(row);
      assert(_needsSpecRebuild || band != null);
      final RawTableBand bandSpec = _needsSpecRebuild ? delegate.buildRowSpec(row) : band!.spec;
      band ??= _Band();
      band.update(
        isSticky: isSticky,
        spec: bandSpec,
        start: isSticky ? startOfStickyRow : startOfRow,
        extent: bandSpec.extent.calculateExtent(RawTableBandExtentDelegate(
          viewportExtent: size.height,
          precedingExtent: isSticky ? startOfStickyRow : startOfRow,
        )),
      );
      newRowMetrics[row] = band;
      if (!isSticky) {
        final double endOfRow = startOfRow + band.extent;
        if (endOfRow >= verticalOffset.pixels && _firstVisibleRow == null) {
          _firstVisibleRow = row;
        }
        if (endOfRow >= verticalOffset.pixels + size.height - startOfStickyRow && _lastVisibleRow == null) {
          _lastVisibleRow = row;
        }
        startOfRow = endOfRow;
      } else {
        startOfStickyRow = startOfStickyRow + band.extent;
      }
    }
    assert(newRowMetrics.length >= delegate.numberOfStickyRows);
    for (final _Band band in _rowMetrics.values) {
      band.dispose();
    }
    _rowMetrics = newRowMetrics;

    _needsSpecRebuild = false;
    _needsSpecExtentUpdate = false;

    final double maxVerticalScrollExtent;
    if (_rowMetrics.length <= delegate.numberOfStickyRows) {
      assert(_firstVisibleRow == null && _lastVisibleRow == null);
      maxVerticalScrollExtent = 0.0;
    } else {
      final int lastRow = _rowMetrics.length - 1;
      if (_firstVisibleRow != null) {
        _lastVisibleRow ??= lastRow;
      }
      final _Band lastAvailableRow = _rowMetrics[lastRow]!;
      final double endOfLastAvailableRow = lastAvailableRow.start + lastAvailableRow.extent;
      maxVerticalScrollExtent = math.max(0.0, endOfLastAvailableRow - size.height + startOfStickyRow);
    }

    final double maxHorizontalScrollExtent;
    if (_columnMetrics.length <= delegate.numberOfStickyColumns) {
      assert(_firstVisibleColumn == null && _lastVisibleColumn == null);
      maxHorizontalScrollExtent = 0.0;
    } else {
      final int lastColumn = _columnMetrics.length - 1;
      if (_firstVisibleColumn != null) {
        _lastVisibleColumn ??= lastColumn;
      }
      final _Band lastAvailableColumn = _columnMetrics[lastColumn]!;
      final double endOfLastAvailableColumn = lastAvailableColumn.start + lastAvailableColumn.extent;
      maxHorizontalScrollExtent = math.max(0.0, endOfLastAvailableColumn - size.width + startOfStickyColumn);
    }

    bool acceptedDimension = horizontalOffset.applyContentDimensions(0.0, maxHorizontalScrollExtent);
    acceptedDimension = verticalOffset.applyContentDimensions(0.0, maxVerticalScrollExtent) || acceptedDimension;
    if (!acceptedDimension) {
      _updateFirstAndLastVisibleCell();
    }
  }

  double get _coveredByStickyRows => _lastStickyRow != null ? _rowMetrics[_lastStickyRow]!.end : 0.0;
  double get _coveredByStickyColumns => _lastStickyColumn != null ? _columnMetrics[_lastStickyColumn]!.end : 0.0;

  void _updateFirstAndLastVisibleCell() {
    _firstVisibleColumn = null;
    _lastVisibleColumn = null;
    final double lastVisibleColumnPixel = horizontalOffset.pixels + size.width - _coveredByStickyColumns;
    for (int column = 0; column < _columnMetrics.length; column++) {
      if (_columnMetrics[column]!.isSticky) {
        continue;
      }
      final double endOfColumn = _columnMetrics[column]!.end;
      if (endOfColumn >= horizontalOffset.pixels && _firstVisibleColumn == null) {
        _firstVisibleColumn = column;
      }
      if (endOfColumn >= lastVisibleColumnPixel && _lastVisibleColumn == null) {
        _lastVisibleColumn = column;
        break;
      }
    }
    if (_firstVisibleColumn != null) {
      _lastVisibleColumn ??= _columnMetrics.length - 1;
    }

    _firstVisibleRow = null;
    _lastVisibleRow = null;
    final double lastVisibleRowPixel = verticalOffset.pixels + size.height - _coveredByStickyRows;
    for (int row = 0; row < _rowMetrics.length; row++) {
      if (_rowMetrics[row]!.isSticky) {
        continue;
      }
      final double endOfRow = _rowMetrics[row]!.end;
      if (endOfRow >= verticalOffset.pixels && _firstVisibleRow == null) {
        _firstVisibleRow = row;
      }
      if (endOfRow >= lastVisibleRowPixel && _lastVisibleRow == null) {
        _lastVisibleRow = row;
        break;
      }
    }
    if (_firstVisibleRow != null) {
      _lastVisibleRow ??= _rowMetrics.length - 1;
    }
  }

  @override
  void performLayout() {
    if (_needsSpecRebuild || _needsSpecExtentUpdate) {
      _updateMetrics();
    } else {
      _updateFirstAndLastVisibleCell();
    }

    if (_firstVisibleCell == null && _lastStickyRow == null && _lastStickyColumn == null) {
      assert(_lastVisibleCell == null);
      assert(_children.isEmpty);
      return;
    }

    final double? offsetIntoColumn = _firstVisibleColumn != null
        ? horizontalOffset.pixels - _columnMetrics[_firstVisibleColumn]!.start - _coveredByStickyColumns
        : null;
    final double? offsetIntoRow = _firstVisibleRow != null
        ? verticalOffset.pixels - _rowMetrics[_firstVisibleRow]!.start - _coveredByStickyRows
        : null;

    cellManager.startLayout();
    if (_lastStickyRow != null && _lastStickyColumn != null) {
      _layoutCells(
        start: const _CellIndex(row: 0, column: 0),
        end: _CellIndex(row: _lastStickyRow!, column: _lastStickyColumn!),
        offset: Offset.zero,
      );
    }
    if (_lastStickyRow != null && _firstVisibleColumn != null) {
      assert(_lastVisibleColumn != null);
      assert(offsetIntoColumn != null);
      _layoutCells(
        start: _CellIndex(row: 0, column: _firstVisibleColumn!),
        end: _CellIndex(row: _lastStickyRow!, column: _lastVisibleColumn!),
        offset: Offset(offsetIntoColumn!, 0),
      );
    }
    if (_lastStickyColumn != null && _firstVisibleRow != null) {
      assert(_lastVisibleRow != null);
      assert(offsetIntoRow != null);
      _layoutCells(
        start: _CellIndex(row: _firstVisibleRow!, column: 0),
        end: _CellIndex(row: _lastVisibleRow!, column: _lastStickyColumn!),
        offset: Offset(0, offsetIntoRow!),
      );
    }
    if (_firstVisibleCell != null) {
      assert(_lastVisibleCell != null);
      assert(offsetIntoColumn != null);
      assert(offsetIntoRow != null);
      _layoutCells(
        start: _firstVisibleCell!,
        end: _lastVisibleCell!,
        offset: Offset(offsetIntoColumn!, offsetIntoRow!),
      );
    }
    invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
      cellManager.endLayout();
    });

    _needsCellRebuild = false;
    assert(_debugOrphans?.isEmpty ?? true);
  }

  void _layoutCells({required _CellIndex start, required _CellIndex end, required Offset offset}) {
    double yPaintOffset = -offset.dy;
    RenderBox? previousCell;
    for (int row = start.row; row <= end.row; row += 1) {
      double xPaintOffset = -offset.dx;
      final _Band rowMetric = _rowMetrics[row]!;
      final double rowHeight = rowMetric.extent;
      for (int column = start.column; column <= end.column; column += 1) {
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
  }

  final LayerHandle<ClipRectLayer> _clipStickyRowsHandle = LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipRectLayer> _clipStickyColumnsHandle = LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipRectLayer> _clipCellsHandle = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_firstVisibleCell == null && _lastStickyRow == null && _lastStickyColumn == null) {
      assert(_lastVisibleCell == null);
      assert(_children.isEmpty);
      return;
    }
    // TODO: Only if we actually have overflow and clipping is enabled.
    // TODO: make type of clipping configurable.
    if (_firstVisibleCell != null) {
      assert(_lastVisibleCell != null);
      _clipCellsHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(_coveredByStickyColumns, _coveredByStickyRows, size.width - _coveredByStickyColumns, size.height - _coveredByStickyRows),
        (PaintingContext context, Offset offset) {
          _paintCells(
            context: context,
            offset: offset,
            start: _firstVisibleCell!,
            end: _lastVisibleCell!,
          );
        },
        oldLayer: _clipCellsHandle.layer,
      );
    }

    if (_lastStickyColumn != null && _firstVisibleRow != null) {
      _clipStickyColumnsHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(0.0, _coveredByStickyRows, _coveredByStickyColumns, size.height - _coveredByStickyRows),
        (PaintingContext context, Offset offset) {
          _paintCells(
            context: context,
            offset: offset,
            start: _CellIndex(row: _firstVisibleRow!, column: 0),
            end: _CellIndex(row: _lastVisibleRow!, column: _lastStickyColumn!),
          );
        },
        oldLayer: _clipStickyColumnsHandle.layer,
      );
    } else {
      _clipStickyColumnsHandle.layer = null;
    }

    if (_lastStickyRow != null && _firstVisibleColumn != null) {
      _clipStickyRowsHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(_coveredByStickyColumns, 0.0, size.width - _coveredByStickyColumns, _coveredByStickyRows),
        (PaintingContext context, Offset offset) {
          _paintCells(
            context: context,
            offset: offset,
            start: _CellIndex(row: 0, column: _firstVisibleColumn!),
            end: _CellIndex(row: _lastStickyRow!, column: _lastVisibleColumn!),
          );
        },
        oldLayer: _clipStickyRowsHandle.layer,
      );
    } else {
      _clipStickyRowsHandle.layer = null;
    }

    if (_lastStickyRow != null && _lastStickyColumn != null) {
      _paintCells(
        context: context,
        offset: offset,
        start: const _CellIndex(row: 0, column: 0),
        end: _CellIndex(row: _lastStickyRow!, column: _lastStickyColumn!),
      );
    }
  }

  _RawTableViewportParentData _parentDataOf(RenderBox child) {
    return child.parentData! as _RawTableViewportParentData;
  }

  RenderBox? _cellAfter(RenderBox child) {
    return _parentDataOf(child).nextSibling;
  }

  void _paintCells({required PaintingContext context, required _CellIndex start, required _CellIndex end, required Offset offset}) {
    final LinkedHashMap<Rect, RawTableBandDecoration> _foregroundColumns = LinkedHashMap<Rect, RawTableBandDecoration>();
    for (int column = start.column; column <= end.column; column++) {
      final _Band band = _columnMetrics[column]!;
      if (band.spec.backgroundDecoration != null || band.spec.foregroundDecoration != null) {
        final _RawTableViewportParentData startParentData = _parentDataOf(_children[_CellIndex(row: start.row, column: column)]!);
        final RenderBox endChild = _children[_CellIndex(row: end.row, column: column)]!;
        final Rect rect = Rect.fromPoints(startParentData.offset + offset, _parentDataOf(endChild).offset + Offset(endChild.size.width, endChild.size.height) + offset);
        if (band.spec.backgroundDecoration != null) {
          band.spec.backgroundDecoration!.paint(context.canvas, rect, Axis.vertical);
        } else {
          assert(band.spec.foregroundDecoration != null);
          _foregroundColumns[rect] = band.spec.foregroundDecoration!;
        }
      }
    }
    final LinkedHashMap<Rect, RawTableBandDecoration> _foregroundRows = LinkedHashMap<Rect, RawTableBandDecoration>();
    for (int row = start.row; row <= end.row; row++) {
      final _Band band = _rowMetrics[row]!;
      if (band.spec.backgroundDecoration != null || band.spec.foregroundDecoration != null) {
        final _RawTableViewportParentData startParentData = _parentDataOf(_children[_CellIndex(row: row, column: start.column)]!);
        final RenderBox endChild = _children[_CellIndex(row: row, column: end.column)]!;
        final Rect rect = Rect.fromPoints(startParentData.offset + offset, _parentDataOf(endChild).offset + Offset(endChild.size.width, endChild.size.height) + offset);
        if (band.spec.backgroundDecoration != null) {
          band.spec.backgroundDecoration!.paint(context.canvas, rect, Axis.horizontal);
        } else {
          assert(band.spec.foregroundDecoration != null);
          _foregroundRows[rect] = band.spec.foregroundDecoration!;
        }
      }
    }
    for (RenderBox? cell = _children[start]; cell != null; cell = _cellAfter(cell)) {
      final _RawTableViewportParentData parentData = _parentDataOf(cell);
      context.paintChild(cell, offset + parentData.offset);
    }
    _foregroundRows.forEach((Rect rect, RawTableBandDecoration decoration) {
      decoration.paint(context.canvas, rect, Axis.horizontal);
    });
    _foregroundColumns.forEach((Rect rect, RawTableBandDecoration decoration) {
      decoration.paint(context.canvas, rect, Axis.vertical);
    });
  }

  @override
  void dispose() {
    _clipStickyRowsHandle.layer = null;
    _clipStickyColumnsHandle.layer = null;
    _clipCellsHandle.layer = null;
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

  // TODO: Allow tables with unknown column.row count, i.e. numberOfColumns or numberOfRows is null.
  //   Also: buildColumnSpec/buildRowSpec may then return null to indicate the end.
  int get numberOfColumns;
  int get numberOfRows;

  int get numberOfStickyRows => 0;
  int get numberOfStickyColumns => 0;

  RawTableBand buildColumnSpec(int column);
  RawTableBand buildRowSpec(int row);

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

  bool get isSticky => _isSticky;
  late bool _isSticky;

  double get end => start + extent;

  // ---- Band Management ----

  void update({required RawTableBand spec, required double start, required double extent, required bool isSticky}) {
    _start = start;
    _extent = extent;
    _isSticky = isSticky;
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
