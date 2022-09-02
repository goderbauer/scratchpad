import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  // TODO(goderbauer): Better error when accidentally using runApp.
  runPlainApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color _background = Colors.white;

  late List<Widget> _views = [
    View(
      view: PlatformDispatcher.instance.views.first,
      child: MainScreen(
        onCreateView: _handleCreateView,
        onChangeBackground: _handleBackgroundChange,
      ),
    ),
  ];

  Future<void> _handleCreateView() async {
    final int viewId = await _ViewManager.createView();
    if (!mounted) {
      return;
    }
    setState(() {
      _views = _views.toList()..add(
        View(
          view: PlatformDispatcher.instance.views.firstWhere((FlutterView view) => view.viewId == viewId),
          child: const TopLevelView(),
        ),
      );
    });
  }
  void _handleBackgroundChange() {
    setState(() {
      _background = _background == Colors.white ? Colors.grey : Colors.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundColor(
      color: _background,
      child: StageManager(
        stages: _views,
      ),
    );
  }
}

// TODO(window): hot reload/restart.

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.onCreateView, required this.onChangeBackground});

  final VoidCallback onCreateView;
  final VoidCallback onChangeBackground;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Widget> _sideViews = const [];

  Future<void> _createSideView() async {
    final int viewId = await _ViewManager.createView();
    if (!mounted) {
      return;
    }
    setState(() {
      _sideViews = _sideViews.toList()..add(
        View(
          view: PlatformDispatcher.instance.views.firstWhere((FlutterView view) => view.viewId == viewId),
          child: const SideView(),
        ),
      );
    });
  }

  Color _sideBackground = Colors.white;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("MAIN VIEW ${View.of(context).viewId}")),
        body: Container(
          color: BackgroundColor.of(context),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onCreateView,
                      child: const Text('top-level view'),
                    ),
                    const SizedBox(width: 8),
                    BackgroundColor(
                      color: _sideBackground,
                      child: SideStageManager(
                        stages: _sideViews,
                        child: OutlinedButton(
                          onPressed: _createSideView,
                          child: const Text('side view'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onChangeBackground,
                      child: const Text('change top color'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _sideBackground = _sideBackground == Colors.white ? Colors.lightGreen : Colors.white;
                        });
                      },
                      child: const Text('change side color'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    SemanticsBinding.instance.setSemanticsEnabled(!SemanticsBinding.instance.semanticsCoordinator.enabled);
                  },
                  child: const Text('toggle semantics'),
                ),
              ],
            )
          ),
        )
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
        body: SizedBox.expand(
          child: ColoredBox(
            color: BackgroundColor.of(context),
            child: const Center(
              child: Text("Hello"),
            ),
          ),
        ),
      ),
    );
  }
}

class SideView extends StatelessWidget {
  const SideView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: BackgroundColor.of(context),
        child: Center(
          child: Text("SizeView ${View.of(context).viewId}"),
        ),
      ),
    );
  }
}

class BackgroundColor extends InheritedWidget {
  const BackgroundColor({super.key, required this.color, required super.child});

  final Color color;

  @override
  bool updateShouldNotify(BackgroundColor oldWidget) {
    return color != oldWidget.color;
  }

  static Color of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BackgroundColor>()!.color;
  }
}




class _ViewManager {
  static const MethodChannel _channel = OptionalMethodChannel('flutter/window');

  static Future<int> createView() async {
    return (await _channel.invokeMethod('new')) as int;
  }
}
