import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // TODO(goderbauer): Better error when accidentally uing runApp.
  runPlainApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<Widget> _views = [
    View(
      view: PlatformDispatcher.instance.views.first,
      child: MainScreen(
        onCreateView: _onCreateView,
      ),
    ),
  ];

  Future<void> _onCreateView() async {
    final int viewId = await _ViewManager.createView();
    if (!mounted) {
      return;
    }
    setState(() {
      _views = _views.toList()..add(
        View(
          view: PlatformDispatcher.instance.views.firstWhere((FlutterView view) => view.viewId == viewId),
          child: const TopLevelView(),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ViewStages(
      children: _views,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.onCreateView});

  final VoidCallback onCreateView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("MAIN VIEW ${View.of(context).viewId}")),
        floatingActionButton: FloatingActionButton(
          onPressed: onCreateView,
        ),
      ),
    );
  }
}

class TopLevelView extends StatelessWidget {
  const TopLevelView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Top Level View ${View.of(context).viewId}")),
      ),
    );
  }
}


class _ViewManager {
  static const MethodChannel _channel = OptionalMethodChannel('flutter/window');

  static Future<int> createView() async {
    return (await _channel.invokeMethod('new')) as int;
  }
}
