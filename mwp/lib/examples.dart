import 'package:flutter/material.dart';

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  // Configure a WindowController with initial window properties.
  final WindowController _controller = WindowController(
    constraints: BoxConstraints.tight(const Size(400, 800)),
  );

  @override
  Widget build(BuildContext context) {
    // Pass controller to Window widget, which will create a window configured
    // according to the controller. The widget's child will be rendered into the
    // window.
    return Window(
      controller: _controller,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Use WindowController to modify window properties.
                _controller.size = const Size(500, 500);
              },
              child: const Text('Set size to 500x500'),
            ),
            ElevatedButton(
              onPressed: () {
                // Use WindowController to modify window properties.
                print('Window size: ${_controller.size}');
              },
              child: const Text('Print current size'),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowController implements Listenable {
  WindowController({
    BoxConstraints constraints = const BoxConstraints(),
    bool minimizable = true,
    bool closable = true,
    // ...
  });
}
