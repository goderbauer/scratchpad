import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'window.dart';

class WindowedTooltip extends StatefulWidget {
  const WindowedTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final Widget child;
  final String message;

  @override
  State<WindowedTooltip> createState() => _WindowedTooltipState();
}

class _WindowedTooltipState extends State<WindowedTooltip> {
  bool _showTooltip = false;
  final WindowController _controller = WindowController(
      // constraints: const BoxConstraints(),
      );

  @override
  Widget build(BuildContext context) {
    return ViewAnchor(
      view: _showTooltip
          ? Window(
              controller: _controller,
              child: Container(
                color: Colors.yellowAccent,
                child: Center(
                  child: Text(widget.message),
                ),
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
