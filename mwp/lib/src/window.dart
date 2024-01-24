import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowController {}

class Window extends StatefulWidget {
  const Window({super.key, this.controller, required this.child});

  final WindowController? controller;
  final Widget child;

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> with WidgetsBindingObserver {
  FlutterView? _view;

  static const Widget _placeholder = ViewCollection(views: <Widget>[]);

  @override
  void didChangeMetrics() {
    print(WidgetsBinding.instance.platformDispatcher.views);
  }

  @override
  void initState() {
    super.initState();
    _createWindow();
  }

  @override
  void dispose() {
    _disposeWindow();
    super.dispose();
  }

  Future<void> _createWindow() async {
    int? viewId = await _windowChannel.invokeMethod('create');
    print('Received: $viewId');
    if (viewId == null) {
      return;
    }
    // TODO: deal with unmounted.
    setState(() {
      _view = WidgetsBinding.instance.platformDispatcher.view(id: viewId);
    });
  }

  // Method must remain callable even if unmounted.
  void _disposeWindow() async {
    if (_view != null) {
      _windowChannel.invokeMethod('dispose', _view!.viewId);
      _view = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _view == null
        ? _placeholder
        : View(
            view: _view!,
            child: widget.child,
          );
  }
}

const MethodChannel _windowChannel = OptionalMethodChannel('flutter/window');

// Thought: Should the window be attached to the controller?
