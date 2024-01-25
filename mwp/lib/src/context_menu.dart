import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'window.dart';

class WindowedContextMenu extends StatefulWidget {
  const WindowedContextMenu({
    super.key,
    required this.entries,
    required this.child,
  });

  final Widget child;
  final List<Widget> entries;

  @override
  State<WindowedContextMenu> createState() => _WindowedContextMenuState();
}

class _WindowedContextMenuState extends State<WindowedContextMenu> {
  WindowController? _controller;

  @override
  Widget build(BuildContext context) {
    return ViewAnchor(
      view: _controller != null
          ? Window(
        controller: _controller,
        child: Container(
          color: Colors.grey.withAlpha(250),
          child: Column(
            children: widget.entries,
          )
        ),
      )
          : null,
      child: TapRegion(
        onTapOutside: (_) {
          setState(() {
            _controller = null;
          });
        },
        child: GestureDetector(
          onSecondaryTapUp: (TapUpDetails details) {
            setState(() {
              _controller = WindowController(
                offset: details.globalPosition + const Offset(10, 20),
                viewAnchor: View.of(context),
                size: const Size(150, 50*10),
              );
            });
          },
          child: widget.child,
        ),
      ),
    );
  }
}
