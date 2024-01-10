import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: MyTooltip(
        child: MyButton(),
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  const MyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('tapped');
      },
      child: Container(
        height: 40,
        width: 100,
        color: Colors.red,
      ),
    );
  }
}

class MyTooltip extends StatefulWidget {
  const MyTooltip({super.key, this.child});

  final Widget? child;

  @override
  State<MyTooltip> createState() => _MyTooltipState();
}

class _MyTooltipState extends State<MyTooltip> {
  bool _showTooltip = false;

  // TODO: configure size (= constraints!) and position.
  final WindowController _windowController = WindowController();

  @override
  Widget build(BuildContext context) {
    return ViewAnchor(
      view: _showTooltip
          ? Window(
              controller: _windowController,
              child: Container(
                color: Colors.yellow,
                height: 20,
                width: 250,
              ),
            )
          : null,
      child: MouseRegion(
        onEnter: (PointerEnterEvent event) {
          setState(() {
            _showTooltip = true;
          });
        },
        onExit: (PointerExitEvent event) {
          setState(() {
            _showTooltip = false;
          });
        },
        child: widget.child,
      ),
    );
  }
}

class Window extends StatefulWidget {
  const Window({super.key, this.controller, required this.child});

  final Widget child;
  final WindowController? controller;

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> {
  FlutterWindow? _window;
  bool _windowNeedsConfigurationUpdate = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleWindowConfigurationChange);
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
      widget.controller?.toConfiguration() ?? WindowConfiguration(),
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
  WindowConfiguration toConfiguration();
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
