import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'dart_ui.dart';

class WindowController {
  WindowController({
    this.viewAnchor,
    this.offset,
    this.size, // Should be constraints
    this.pointerEvents = true,
  });

  final Offset? offset; // relative to origin of viewAnchor, if specified.
  final FlutterView? viewAnchor;
  final Size? size;
  final bool pointerEvents;
}

class Window extends StatefulWidget {
  const Window({super.key, this.controller, required this.child});

  final WindowController? controller;
  final Widget child;

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> {
  FlutterWindow? _window;

  static const Widget _placeholder = ViewCollection(views: <Widget>[]);

  @override
  void initState() {
    super.initState();
    _createWindow();
  }

  @override
  void dispose() {
    _window?.close();
    _window = null;
    super.dispose();
  }

  Future<void> _createWindow() async {
    final FlutterWindow window = await WidgetsBinding.instance.platformDispatcher.createWindow(widget.controller?._request);
    if (!mounted) {
      window.close();
      return;
    }
    setState(() {
      _window = window;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _window == null
        ? _placeholder
        : View(
            view: _window!.view,
            child: widget.child,
          );
  }
}

// Thought: Should the window be attached to the controller?
