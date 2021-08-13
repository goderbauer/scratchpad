import 'dart:ui';

import 'package:flutter/painting.dart';

/// A decoration for a [RawTableBand].
class RawTableBandDecoration {
  /// Creates a [RawTableBandDecoration].
  const RawTableBandDecoration({this.border, this.color});

  /// The border drawn around the band.
  final RawTableBandBorder? border;

  /// The color to fill the bounds of the band with.
  final Color? color;

  /// Called to draw the decoration around a band.
  ///
  /// If the band represents a row, `axis` will be [Axis.horizontal]. For
  /// columns, [Axis.vertical] is used.
  ///
  /// The provided `rect` describes the bounds of the band that are currently
  /// visible inside the viewport of the table. The extent of the actual band
  /// may be larger.
  ///
  /// If a band contains sticky parts, [paint] is invoked separately for the sticky
  /// and non-sticky parts. For example: If a row contains a sticky column,
  /// paint is called with the `rect` for the cell representing the sticky
  /// column and separately with a `rect` containing all the other non-sticky
  /// cells.
  void paint(Canvas canvas, Rect rect, Axis axis) {
    if (color != null) {
      canvas.drawRect(rect, Paint()
        ..color = color!
        ..isAntiAlias = false,
      );
    }
    if (border != null) {
      border!.paint(canvas, rect, axis);
    }
  }
}

/// Describes the border for a [RawTableBand].
class RawTableBandBorder {
  /// Creates a [RawTableBandBorder].
  const RawTableBandBorder({this.trailing = BorderSide.none, this.leading = BorderSide.none});

  /// The border to draw on the trailing side of the band.
  ///
  /// The trailing side of a row is the bottom, the trailing side of a column
  /// is its right side.
  final BorderSide trailing;

  /// The border to draw on the leading side of the band.
  ///
  /// The leading side of a row is the top, the trailing side of a column
  /// is its left side.
  final BorderSide leading;

  /// Called to draw the border around a band.
  ///
  /// If the band represents a row, `axis` will be [Axis.horizontal]. For
  /// columns, [Axis.vertical] is used.
  ///
  /// The provided `rect` describes the bounds of the band that are currently
  /// visible inside the viewport of the table. The extent of the actual band
  /// may be larger.
  ///
  /// If a band contains sticky parts, [paint] is invoked separately for the sticky
  /// and non-sticky parts. For example: If a row contains a sticky column,
  /// paint is called with the `rect` for the cell representing the sticky
  /// column and separately with a `rect` containing all the other non-sticky
  /// cells.
  void paint(Canvas canvas, Rect rect, Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        paintBorder(canvas, rect, top: leading, bottom: trailing);
        break;
      case Axis.vertical:
        paintBorder(canvas, rect, left: leading, right: trailing);
        break;
    }
  }
}
