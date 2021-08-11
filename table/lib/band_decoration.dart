import 'dart:ui';

import 'package:flutter/painting.dart';

class RawTableBandDecoration {
  const RawTableBandDecoration({this.border, this.color});

  final RawTableBandBorder? border;
  final Color? color;

  void paint(Canvas canvas, Rect rowRect, Axis axis) {
    if (color != null) {
      canvas.drawRect(rowRect, Paint()..color = color!);
    }
    if (border != null) {
      border!.paint(canvas, rowRect, axis);
    }
  }
}

class RawTableBandBorder {
  const RawTableBandBorder({this.trailing = BorderSide.none, this.leading = BorderSide.none});

  final BorderSide trailing;
  final BorderSide leading;

  void paint(Canvas canvas, Rect rowRect, Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        paintBorder(canvas, rowRect, top: leading, bottom: trailing);
        break;
      case Axis.vertical:
        paintBorder(canvas, rowRect, left: leading, right: trailing);
        break;
    }
  }
}
