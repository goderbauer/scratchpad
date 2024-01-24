import 'package:flutter/material.dart';
import 'package:mwp/src/tooltip.dart';

void main() {
  runApp(
    const MaterialApp(
      home: AuxiliaryWindowApp(),
    ),
  );
}

class AuxiliaryWindowApp extends StatelessWidget {
  const AuxiliaryWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxiliary Window Example'),
      ),
      body: Center(
        child: WindowedTooltip(
          message: 'Hello there! I am a tooltip so wide that the main window cannot contain me. I am ignoring all window bounds. Try to stop me!',
          child: ElevatedButton(
            onPressed: () {
              // Nothing to do.
              print(WidgetsBinding.instance.platformDispatcher.views);
            },
            child: const Text('Hover or right-click me!'),
          ),
        ),
      ),
    );
  }
}
