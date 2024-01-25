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
  WindowController? _controller;

  @override
  Widget build(BuildContext context) {
    return ViewAnchor(
      view: _controller != null
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
            _controller = WindowController(
              offset: event.position + const Offset(5, 5),
              viewAnchor: View.of(context),
              size: const Size(860, 25),
            );
          });
        },
        onExit: (PointerExitEvent event) {
          setState(() {
            _controller = null;
          });
        },
        child: widget.child,
      ),
    );
  }
}
