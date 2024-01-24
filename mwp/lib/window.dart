import 'package:flutter/material.dart';

class Window extends StatefulWidget {
  const Window({super.key, this.controller, required this.child});

  final Widget child;
  final WindowController? controller;

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> {
  FlutterWindow? _window;
  bool _pendingConfigurationUpdate = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _createWindow();
  }

  // TODO: didUpdateWidget (changing controller).

  void _handleWindowConfigurationChange() {
    if (_window == null) {
      _windowNeedsConfigurationUpdate = true;
    } else {
      _window!.configuration = widget.controller!.toConfiguration();
    }
  }

  Future<void> _createWindow() async {
    final FlutterWindow window = await WindowingAPI.createWindow(
      widget.controller?._configuration ?? WindowConfiguration(),
    );
    if (!mounted) {
      window.dispose();
      return;
    }
    setState(() {
      _window = window;
    });
    if (_windowNeedsConfigurationUpdate) {
      _windowNeedsConfigurationUpdate = false;
      _window!.configuration = widget.controller!.toConfiguration();
    }

    // TODO: Connect the window with the window controller.
  }

  @override
  void dispose() {
    super.dispose();
    _window?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_window == null) {
      // TODO: This doesn't work since there is no render tree to attach this to.
      return const SizedBox();
    }
    return View(
      view: _window!.view,
      child: widget.child,
    );
  }
}

abstract class WindowController implements Listenable {
  WindowController({

});

WindowConfiguration _configuration;

void requestUpdate
}

class WindowConfiguration {

}

// Lower level API.

class WindowingAPI {
  static Future<FlutterWindow> createWindow(WindowConfiguration config) async {

  }
}

abstract class FlutterWindow {
  FlutterView get view; // class could also extend FlutterView
  WindowConfiguration configuration;
  void dispose();
}
