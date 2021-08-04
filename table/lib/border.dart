import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

// TODO: unify? with TableBorder.
@immutable
class RawTableBorder {
  const RawTableBorder({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
    this.horizontalInside = BorderSide.none,
    this.verticalInside = BorderSide.none,
    this.borderRadius = BorderRadius.zero,
  });

  factory RawTableBorder.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    final BorderSide side = BorderSide(color: color, width: width, style: style);
    return RawTableBorder(top: side, right: side, bottom: side, left: side, horizontalInside: side, verticalInside: side, borderRadius: borderRadius);
  }

  factory RawTableBorder.symmetric({
    BorderSide inside = BorderSide.none,
    BorderSide outside = BorderSide.none,
  }) {
    return RawTableBorder(
      top: outside,
      right: outside,
      bottom: outside,
      left: outside,
      horizontalInside: inside,
      verticalInside: inside,
    );
  }

  final BorderSide top;
  final BorderSide right;
  final BorderSide bottom;
  final BorderSide left;
  final BorderSide horizontalInside;
  final BorderSide verticalInside;
  final BorderRadius borderRadius;

  // TODO: What to do with "holes" caused by spans?
  void paint(
      Canvas canvas,
      Rect visibleTableRect,
      Iterable<double> innerRowOffsets,
      Iterable<double> innerColumnOffsets,
      Rect outerOffsets, // double.NaN represents that it's not rendered currently.
      ) {
    final Paint paint = Paint();
    final Path path = Path();

    if (innerColumnOffsets.isNotEmpty) {
      switch (verticalInside.style) {
        case BorderStyle.solid:
          paint
            ..color = verticalInside.color
            ..strokeWidth = verticalInside.width
            ..style = PaintingStyle.stroke;
          path.reset();
          for (final double x in innerColumnOffsets) {
            path
              ..moveTo(x, visibleTableRect.top)
              ..lineTo(x, visibleTableRect.bottom);
          }
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none:
          break;
      }
    }

    if (innerRowOffsets.isNotEmpty) {
      switch (horizontalInside.style) {
        case BorderStyle.solid:
          paint
            ..color = horizontalInside.color
            ..strokeWidth = horizontalInside.width
            ..style = PaintingStyle.stroke;
          path.reset();
          for (final double y in innerRowOffsets) {
            path
              ..moveTo(visibleTableRect.left, y)
              ..lineTo(visibleTableRect.right, y);
          }
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none:
          break;
      }
    }

    if (outerOffsets.top != double.nan) {
      switch (top.style) {
        case BorderStyle.solid:
          paint
            ..color = top.color
            ..strokeWidth = top.width
            ..style = PaintingStyle.stroke;
          final double dy = outerOffsets.top + (top.width / 2);
          path
            ..reset()
            ..moveTo(visibleTableRect.left, dy)
            ..lineTo(visibleTableRect.right, dy);
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none:
          break;
      }
    }

    if (outerOffsets.bottom != double.nan) {
      switch (bottom.style) {
        case BorderStyle.solid:
          paint
            ..color = bottom.color
            ..strokeWidth = bottom.width
            ..style = PaintingStyle.stroke;
          final double dy = outerOffsets.bottom - (bottom.width / 2);
          path
            ..reset()
            ..moveTo(visibleTableRect.left, dy)
            ..lineTo(visibleTableRect.right, dy);
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none:
          break;
      }
    }

    if (outerOffsets.left != double.nan) {
      switch (left.style) {
        case BorderStyle.solid:
          paint
            ..color = left.color
            ..strokeWidth = left.width
            ..style = PaintingStyle.stroke;
          final double dx = outerOffsets.left + (left.width / 2);
          path
            ..reset()
            ..moveTo(dx, visibleTableRect.top)
            ..lineTo(dx, visibleTableRect.bottom);
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none:
          break;
      }
    }

    if (outerOffsets.right != double.nan) {
      switch (right.style) {
        case BorderStyle.solid:
          paint
            ..color = right.color
            ..strokeWidth = right.width
            ..style = PaintingStyle.stroke;
          final double dx = outerOffsets.right - (right.width / 2);
          path
            ..reset()
            ..moveTo(dx, visibleTableRect.top)
            ..lineTo(dx, visibleTableRect.bottom);
          canvas.drawPath(path, paint);
          break;
        case BorderStyle.none:
          break;
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is RawTableBorder
        && other.top == top
        && other.right == right
        && other.bottom == bottom
        && other.left == left
        && other.horizontalInside == horizontalInside
        && other.verticalInside == verticalInside
        && other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => hashValues(top, right, bottom, left, horizontalInside, verticalInside, borderRadius);

  @override
  String toString() => 'RawTableBorder($top, $right, $bottom, $left, $horizontalInside, $verticalInside, $borderRadius)';
}
