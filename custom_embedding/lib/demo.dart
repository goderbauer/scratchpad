import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runPlainApp(const MultiWindowCounterApp());
}

class MultiWindowCounterApp extends StatefulWidget {
  const MultiWindowCounterApp({super.key});

  @override
  State<MultiWindowCounterApp> createState() => _MultiWindowCounterAppState();
}

class _MultiWindowCounterAppState extends State<MultiWindowCounterApp> {
  final DataModel _dataModel = DataModel();

  late List<Widget> _views = [
    View(
      view: PlatformDispatcher.instance.views.first,
      child: CounterScreen(
        onCreateCounterWindow: _handleCreateView,
        onCreateResetWindow: _handleCreateReset,
        id: PlatformDispatcher.instance.views.length,
      ),
    ),
  ];

  Future<void> _handleCreateView() async {
    final int viewId = await _ViewManager.createView(height: 450, width: 425);
    if (!mounted) {
      return;
    }
    setState(() {
      _views = [
        ..._views,
        View(
          view: PlatformDispatcher.instance.views
              .firstWhere((FlutterView view) => view.viewId == viewId),
          child: CounterScreen(
            onCreateCounterWindow: _handleCreateView,
            onCreateResetWindow: _handleCreateReset,
            id: PlatformDispatcher.instance.views.length,
          ),
        ),
      ];
    });
  }

  Future<void> _handleCreateReset() async {
    final int viewId = await _ViewManager.createView(height: 150, width: 300);
    if (!mounted) {
      return;
    }
    setState(() {
      _views = [
        ..._views,
        View(
          view: PlatformDispatcher.instance.views
              .firstWhere((FlutterView view) => view.viewId == viewId),
          child: const ResetScreen(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DataModelScope(
      model: _dataModel,
      child: StageManager(
        stages: _views,
      ),
    );
  }
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({
    super.key,
    required this.id,
    required this.onCreateCounterWindow,
    required this.onCreateResetWindow,
  });

  final int id;
  final VoidCallback onCreateCounterWindow;
  final VoidCallback onCreateResetWindow;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: DataModel.of(context).themeColor,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Counter #$id"),
          actions: [
            IconButton(
              onPressed: () {
                final DataModel model = DataModel.of(context);
                model.themeColor =
                    model.themeColor == Colors.blue ? Colors.teal : Colors.blue;
              },
              icon: const Icon(Icons.light_mode_outlined),
            ),
            IconButton(
              onPressed: onCreateResetWindow,
              icon: const Icon(Icons.cleaning_services),
            ),
            IconButton(
              onPressed: onCreateCounterWindow,
              icon: const Icon(Icons.open_in_new),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '${DataModel.of(context).currentCounterValue(id)}',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            DataModel.of(context).increaseCounterValue(id);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class DataModel extends ChangeNotifier {
  static DataModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DataModelScope>()!
        .notifier!;
  }

  MaterialColor get themeColor => _themeColor;
  MaterialColor _themeColor = Colors.blue;
  set themeColor(MaterialColor value) {
    if (value == _themeColor) {
      return;
    }
    _themeColor = value;
    notifyListeners();
  }

  final Map<int, int> _counts = {};

  int currentCounterValue(int id) {
    return _counts[id] ?? 0;
  }

  void increaseCounterValue(int id) {
    _counts[id] = currentCounterValue(id) + 1;
    notifyListeners();
  }

  void resetCounterValues() {
    _counts.clear();
    notifyListeners();
  }
}

class _DataModelScope extends InheritedNotifier<DataModel> {
  const _DataModelScope({
    required super.child,
    required DataModel model,
  }) : super(notifier: model);
}

class ResetScreen extends StatelessWidget {
  const ResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(15), ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            onPressed: () {
              DataModel.of(context).resetCounterValues();
            },
            child: const Text(
              "RESET ALL",
              style: TextStyle(fontSize: 36),
            ),
          ),
        ),
      ),
    );
  }
}


class _ViewManager {
  static const MethodChannel _channel = OptionalMethodChannel('flutter/window');

  static Future<int> createView({required double height, required double width}) async {
    return (await _channel.invokeMethod('new', [height, width])) as int;
  }
}
