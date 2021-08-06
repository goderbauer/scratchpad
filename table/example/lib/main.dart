import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:table/band.dart';
import 'package:table/border.dart';
import 'package:table/table.dart';

void main() {
  runApp(const TableExampleApp());
}

class TableExampleApp extends StatelessWidget {
  const TableExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // showPerformanceOverlay: true,
      title: 'Table Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TableExample(),
    );
  }
}

class TableExample extends StatefulWidget {
  const TableExample({Key? key}) : super(key: key);

  @override
  State<TableExample> createState() => _TableExampleState();
}

class _TableExampleState extends State<TableExample> {
  final ExampleRawTableDelegate delegate = ExampleRawTableDelegate();

  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Example'),
      ),
      body: RawTableScrollView(
        delegate: delegate,
        verticalController: controller,
        border: RawTableBorder.all(color: Colors.deepPurple, width: 10),
      ),
      persistentFooterButtons: <Widget>[
        TextButton(
          onPressed: delegate.switchKeyedChild,
          child: const Text('switch keyed child'),
        ),
        TextButton(
          onPressed: () {
            controller.jumpTo((controller.offset + 2000) % controller.position.maxScrollExtent);
          },
          child: const Text('jump'),
        ),
      ],
    );
  }
}

class ExampleRawTableDelegate extends RawTableDelegate {
  int keyedChildRow = 0;
  int keyedChildColumn = 0;

  void switchKeyedChild() {
    keyedChildRow = keyedChildRow == 0 ? 1 : 0;
    keyedChildColumn = keyedChildColumn == 0 ? 1 : 0;
    notifyListeners();
  }

  @override
  Widget buildCell(BuildContext context, int column, int row) {
    if (column == keyedChildColumn && row == keyedChildRow) {
      return Container(
        key: const ValueKey<String>('counter'),
        color: Colors.pink,
        child: CounterCell(column: column, row: row),
      );
    }
    return Container(
      color: row.isEven
          ? (column.isEven ? Colors.red : Colors.yellow)
          : (column.isEven ? Colors.blue : Colors.green),
      child: Center(child: Text('Tile c: $column, r: $row')),
    );
  }

  @override
  RawTableBand? buildColumnSpec(int column) {
    void onEnter(PointerEnterEvent _) {
      print('> column $column');
    }
    void onExit(PointerExitEvent _) {
      print('< column $column');
    }

    switch (column % 5) {
      case 0:
        return RawTableBand(
          extent: const FixedRawTableBandExtent(100),
          onEnter: onEnter,
          onExit: onExit,
          recognizerFactories: <Type, GestureRecognizerFactory>{
            TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer t) => t.onTap = () => print('T column $column'),
            ),
          },
        );
      case 1:
        return RawTableBand(
          extent: const FractionalRawTableBandExtent(0.5),
          onEnter: onEnter,
          onExit: onExit,
          cursor: SystemMouseCursors.contextMenu,
        );
      case 2:
        return RawTableBand(
          extent: const FixedRawTableBandExtent(120),
          onEnter: onEnter,
          onExit: onExit,
        );
      case 3:
        return RawTableBand(
          extent: const FixedRawTableBandExtent(145),
          onEnter: onEnter,
          onExit: onExit,
        );
      case 4:
        return RawTableBand(
          extent: const FixedRawTableBandExtent(200),
          onEnter: onEnter,
          onExit: onExit,
        );
    }
    return null;
  }

  @override
  RawTableBand? buildRowSpec(int row) {
    void onEnter(PointerEnterEvent _) {
      print('> row $row');
    }
    void onExit(PointerExitEvent _) {
      print('< row $row');
    }

    // return const FixedRawTableDimensionSpec(35);
    switch (row % 3) {
      case 0:
        return RawTableBand(
          extent: const FixedRawTableBandExtent(35),
          onEnter: onEnter,
          onExit: onExit,
          recognizerFactories: <Type, GestureRecognizerFactory>{
            TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer t) => t.onTap = () => print('T row $row'),
            ),
          },
        );
      case 1:
        return RawTableBand(
          extent: const FixedRawTableBandExtent(50),
          onEnter: onEnter,
          onExit: onExit,
          cursor: SystemMouseCursors.click,
        );
      case 2:
        return RawTableBand(
          extent: const FractionalRawTableBandExtent(0.15),
          onEnter: onEnter,
          onExit: onExit,
        );
    }
    return null;
  }

  @override
  int? get columnCount => 8;

  @override
  int? get rowCount => 20;

  @override
  bool shouldRebuild(RawTableDelegate oldDelegate) => true;
}

class CounterCell extends StatefulWidget {
  const CounterCell({
    Key? key,
    required this.row,
    required this.column,
  }) : super(key: key);

  final int row;
  final int column;

  @override
  State<CounterCell> createState() => _CounterCellState();
}

class _CounterCellState extends State<CounterCell> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          count++;
        });
      },
      child: Center(
        child: Text('Count (c: ${widget.column}, r: ${widget.row}): $count'),
      ),
    );
  }
}
