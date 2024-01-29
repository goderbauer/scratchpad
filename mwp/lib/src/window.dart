import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
    final Map<String, Object?> windowSpec = {
      if (widget.controller?.offset != null) ...{
        'offsetX': widget.controller!.offset!.dx,
        'offsetY' : widget.controller!.offset!.dy,
      },
      if (widget.controller?.viewAnchor != null)
        'viewAnchor': widget.controller!.viewAnchor!.viewId,
      if (widget.controller?.size != null) ...{
        'height': widget.controller!.size!.height,
        'width': widget.controller!.size!.width,
      },
      'pointerEvents': widget.controller?.pointerEvents ?? true,
    };
    print(windowSpec);

    int? viewId = await _windowChannel.invokeMethod('create', windowSpec);
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
