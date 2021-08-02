import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false, dragDevices: PointerDeviceKind.values.toSet()), // TODO: How to deal with auto-scrollbars in nested scrolling?
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
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.adjust),
      //   onPressed: () {
      //     controller.jumpTo((controller.offset + 2000) % controller.position.maxScrollExtent);
      //   },
      // ),
      persistentFooterButtons: <Widget>[
        TextButton(onPressed: delegate.switchKeyedChild, child: const Text('switch keyed child')),
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
  RawTableDimensionSpec? buildColumnSpec(int column) {
    switch (column % 5) {
      case 0:
        return const FixedRawTableDimensionSpec(100);
      case 1:
        return const ViewportFractionRawTableDimensionSpec(0.5);
      case 2:
        return const FixedRawTableDimensionSpec(120);
      case 3:
        return const FixedRawTableDimensionSpec(145);
      case 4:
        return const FixedRawTableDimensionSpec(200);
    }
    return null;
  }

  @override
  RawTableDimensionSpec? buildRowSpec(int row) {
    // return const FixedRawTableDimensionSpec(35);
    switch (row % 3) {
      case 0:
        return const FixedRawTableDimensionSpec(35);
      case 1:
        return const FixedRawTableDimensionSpec(50);
      case 2:
        return const ViewportFractionRawTableDimensionSpec(0.15);
    }
    return null;
  }

  @override
  int? get columnCount => 8;

  @override
  int? get rowCount => 1000;

  @override
  bool shouldRebuild(RawTableDelegate oldDelegate) => true;
}

class CounterCell extends StatefulWidget {
  const CounterCell({Key? key, required this.row, required this.column}) : super(key: key);

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
      child: Center(child: Text('Count (c: ${widget.column}, r: ${widget.row}): $count')),
    );
  }
}
