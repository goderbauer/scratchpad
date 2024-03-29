import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:table/raw.dart';

// ignore_for_file: public_member_api_docs

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
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: RawTableView(
          delegate: delegate,
          verticalController: controller,
        ),
      ),
      persistentFooterButtons: <Widget>[
        TextButton(
          onPressed: () {
            controller.jumpTo((controller.offset + 2000) % controller.position.maxScrollExtent);
          },
          child: const Text('jump'),
        ),
        TextButton(
          onPressed: () {
            delegate.numberOfRows += 10;
            if (controller.hasClients && controller.position.pixels == controller.position.maxScrollExtent) {
              SchedulerBinding.instance!.addPostFrameCallback((_) {
                controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(seconds: 1), curve: Curves.ease);
              });
            }
          },
          child: const Text('add 10'),
        ),
      ],
    );
  }
}

class ExampleRawTableDelegate extends RawTableDelegate {

  @override
  Widget buildCell(BuildContext context, int column, int row) {
    return Padding(
      padding: EdgeInsets.only(right: column == numberOfStickyColumns - 1 ? 5 : 0, bottom: row == numberOfStickyRows - 1 ? 5 : 0),
      child: Center(child: Text('Tile c: $column, r: $row, v: ${_rows[row]}')),
    );
  }

  @override
  RawTableBand buildColumnSpec(int column) {
    void onEnter(PointerEnterEvent _) {
      print('> column $column');
    }
    void onExit(PointerExitEvent _) {
      print('< column $column');
    }

    final RawTableBandDecoration decoration = RawTableBandDecoration(
      border: RawTableBandBorder(
        trailing: BorderSide(
          color: Colors.black,
          width: column == numberOfStickyColumns - 1 ? 5 : 0,
          style: BorderStyle.solid,
        ),
      ),
    );

    switch (column % 5) {
      case 0:
        return RawTableBand(
          foregroundDecoration: decoration,
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
          foregroundDecoration: decoration,
          extent: const FractionalRawTableBandExtent(0.5),
          onEnter: onEnter,
          onExit: onExit,
          cursor: SystemMouseCursors.contextMenu,
        );
      case 2:
        return RawTableBand(
          foregroundDecoration: decoration,
          extent: const FixedRawTableBandExtent(120),
          onEnter: onEnter,
          onExit: onExit,
        );
      case 3:
        return RawTableBand(
          foregroundDecoration: decoration,
          extent: const FixedRawTableBandExtent(145),
          onEnter: onEnter,
          onExit: onExit,
        );
      case 4:
        return RawTableBand(
          foregroundDecoration: decoration,
          extent: const FixedRawTableBandExtent(200),
          onEnter: onEnter,
          onExit: onExit,
        );
    }
    throw 'unreachable';
  }

  @override
  RawTableBand buildRowSpec(int row) {
    void onEnter(PointerEnterEvent _) {
      print('> row $row');
    }
    void onExit(PointerExitEvent _) {
      print('< row $row');
    }

    final RawTableBandDecoration decoration = RawTableBandDecoration(
      color: row.isEven ? Colors.grey : null,
      border: RawTableBandBorder(
        trailing: BorderSide(
          color: Colors.black,
          width: 5,
          style: row == numberOfStickyRows - 1 ? BorderStyle.solid : BorderStyle.none,
        ),
      ),
    );

    // return const FixedRawTableDimensionSpec(35);
    switch (row % 3) {
      case 0:
        return RawTableBand(
          backgroundDecoration: decoration,
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
          backgroundDecoration: decoration,
          extent: const FixedRawTableBandExtent(50),
          onEnter: onEnter,
          onExit: onExit,
          cursor: SystemMouseCursors.click,
        );
      case 2:
        return RawTableBand(
          backgroundDecoration: decoration,
          extent: const FractionalRawTableBandExtent(0.15),
          onEnter: onEnter,
          onExit: onExit,
        );
    }
    throw 'unreachable';
  }

  @override
  int get numberOfColumns => 20;

  List<int> _rows = List<int>.generate(100, (int index) => index);

  @override
  int get numberOfRows => _rows.length;
  set numberOfRows(int value) {
    if (value == numberOfRows) {
      return;
    }
    _rows = List<int>.generate(value, (int index) => index);
    notifyListeners();
  }

  @override
  int get numberOfStickyRows => 0;

  @override
  int get numberOfStickyColumns => 0;

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
