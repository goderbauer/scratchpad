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
      showPerformanceOverlay: true,
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
  final RawTableDelegate delegate = ExampleRawTableDelegate();

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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.adjust),
        onPressed: () {
          controller.jumpTo((controller.offset + 2000) % controller.position.maxScrollExtent);
        },
      ),
    );
  }
}

class ExampleRawTableDelegate extends RawTableDelegate {
  @override
  Widget buildCell(BuildContext context, int column, int row) {
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
