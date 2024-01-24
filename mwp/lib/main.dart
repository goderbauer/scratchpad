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
