import 'package:flutter/material.dart';
import 'package:mwp/src/context_menu.dart';
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
    final List<Widget> entries = List.filled(
      10,
      ElevatedButton(
        onPressed: () {
          print('Tap');
        },
        child: const Text('Hello'),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxiliary Window Example'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WindowedTooltip(
              message:
                  'Hello there! I am a tooltip so wide that the main window cannot contain me. I am ignoring all window bounds. Try to stop me!',
              child: ElevatedButton(
                onPressed: () {
                  // Nothing to do.
                  print(View.of(context).devicePixelRatio);
                },
                child: const Text('Hover me!'),
              ),
            ),
            const SizedBox(height: 40),
            WindowedContextMenu(
              entries: entries,
              child: Container(
                color: Colors.blue,
                height: 40,
                width: 150,
                child: const Center(child: Text('Right click me!')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
