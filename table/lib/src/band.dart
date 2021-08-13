import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'band_decoration.dart';

/// Defines the extent, visual appearance, and gesture handling of a row or
/// column in a [RawTableView].
///
/// A band refers to either a column or a row in a table.
class RawTableBand {
  /// Creates a [RawTableBand].
  ///
  /// The [extent] argument must be provided.
  const RawTableBand({
    required this.extent,
    this.recognizerFactories = const <Type, GestureRecognizerFactory>{},
    this.onEnter,
    this.onExit,
    this.cursor = MouseCursor.defer,
    this.backgroundDecoration,
    this.foregroundDecoration,
  });

  // ---- Sizing ----

  /// Defines the extent of the band.
  ///
  /// If the band represents a row, this is the height of the row. If it
  /// represents a column, this is the width of the column.
  final RawTableBandExtent extent;

  // ---- Gestures & Mouse ----

  /// Factory for creating [GestureRecognizer]s that want to compete for
  /// gestures within the [extent] of the band.
  ///
  /// If this band represents a row, a factory for a [TapGestureRecognizer]
  /// could for example be provided here to recognize taps within the bounds
  /// of the row.
  ///
  /// The content of a cell gets first dips on handling pointer events. Next
  /// up are any recognizers defined for rows, followed by the recognizers
  /// defined for columns.
  final Map<Type, GestureRecognizerFactory> recognizerFactories;

  /// Triggers when a mouse pointer, with or without buttons pressed, has
  /// entered the region encompassing the row or column described by this band.
  ///
  /// This callback is triggered when the pointer has started to be contained by
  /// the region, either due to a pointer event, or due to the movement or
  /// appearance of the region. This method is always matched by a later
  /// [onExit] call.
  final PointerEnterEventListener? onEnter;

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// exited the region encompassing the row or column described by this band.
  ///
  /// This callback is triggered when the pointer has stopped being contained
  /// by the region, either due to a pointer event, or due to the movement or
  /// disappearance of the region. This method always matches an earlier
  /// [onEnter] call.
  final PointerExitEventListener? onExit;

  /// Mouse cursor to show when the mouse hovers over this band.
  ///
  /// Defaults to [MouseCursor.defer].
  final MouseCursor cursor;

  /// The [RawTableBandDecoration] to paint behind the content of this band.
  ///
  /// The [backgroundDecoration]s of columns are painted before the
  /// [backgroundDecoration]s of rows. On top of that, the content of the
  /// individual cells in this band are painted. That's followed up with the
  /// [foregroundDecoration]s of the rows and the [foregroundDecoration] of the
  /// columns.
  ///
  /// The decorations of sticky rows and columns are painted separately from
  /// the decoration of non-sticky rows and columns.
  final RawTableBandDecoration? backgroundDecoration;

  /// The [RawTableBandDecoration] to paint behind the content of this band.
  ///
  /// The [backgroundDecoration]s of columns are painted before the
  /// [backgroundDecoration]s of rows. On top of that, the content of the
  /// individual cells in this band are painted. That's followed up with the
  /// [foregroundDecoration]s of the rows and the [foregroundDecoration] of the
  /// columns.
  ///
  /// The decorations of sticky rows and columns are painted separately from
  /// the decoration of non-sticky rows and columns.
  final RawTableBandDecoration? foregroundDecoration;
}

/// Delegate passed to [RawTableBandExtent.calculateExtent].
///
/// Provides access to metrics from the [RawTableView] that a
/// [RawTableBandExtent] may need to calculate its extent.
class RawTableBandExtentDelegate {
  /// Creates a [RawTableBandExtentDelegate].
  ///
  /// Usually, only [RawTableView]s need to create instances of this class.
  const RawTableBandExtentDelegate({required this.viewportExtent, required this.precedingExtent});

  /// The size of the viewport in the axis-direction of the band.
  ///
  /// If the [RawTableBandExtent] calculates the extent of a row, this is the
  /// height of the viewport. If it calculates the extent of a column, this
  /// is the width of the viewport.
  final double viewportExtent;

  /// The scroll extent that has already been used up by previous bands.
  ///
  /// If the [RawTableBandExtent] calculates the extent of a row, this is the
  /// sum of all row extents prior to this row. If it calculates the extent
  /// of a column, this is the sum of all previous columns.
  final double precedingExtent;
}

/// Defines the extent of a [RawTableBand].
///
/// If the band is a row, its extent is the height of the row. If the band is
/// a column, it's the width of that column.
abstract class RawTableBandExtent {
  /// Creates a [RawTableBandExtent].
  const RawTableBandExtent();

  /// Calculates the actual extent of the band in pixels.
  ///
  /// To assist with the calculation, table metrics obtained from the provided
  /// [RawTableBandExtentDelegate] may be used.
  double calculateExtent(RawTableBandExtentDelegate delegate);
}

/// A band extent with a fixed [pixel] value.
class FixedRawTableBandExtent extends RawTableBandExtent {
  /// Creates a [FixedRawTableBandExtent].
  ///
  /// The provided [pixels] value must be equal to or grater then zero.
  const FixedRawTableBandExtent(this.pixels) : assert(pixels >= 0.0);

  /// The extent of the band in pixels.
  final double pixels;

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => pixels;
}

/// Specified the band extent as a fraction of the viewport extent.
///
/// For example, a column with a 1.0 as [fraction] will be as wide as the
/// viewport.
class FractionalRawTableBandExtent extends RawTableBandExtent {
  /// Creates a [FractionalRawTableBandExtent].
  ///
  /// The provided [fraction] value must be equal to or grater then zero.
  const FractionalRawTableBandExtent(this.fraction) : assert(fraction >= 0.0);

  /// The fraction of the [RawTableBandExtentDelegate.viewportExtent] that the
  /// band should occupy.
  final double fraction;

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => delegate.viewportExtent * fraction;
}

/// Specifies that the band should occupy the remaining space in the viewport.
///
/// If the previous band can already fill out the viewport, this will evaluate
/// the band's extent to zero. If the previous band cannot fill out the viewport,
/// this band's extent will be whatever space is left to fill out the viewport.
///
/// To avoid that the band's extent evaluates to zero, consider combining this
/// extent with another extent. The following example will make sure that the
/// band's extent is at least 200 pixels, but if there's more than that available
/// in the viewport, it will fill all that space.:
///
/// ```dart
/// const MaxRawTableBandExtent(FixedRawTableBandExtent(200.0), RemainingRawTableBandExtent());
/// ```
class RemainingRawTableBandExtent extends RawTableBandExtent {
  /// Creates a [RemainingRawTableBandExtent].
  const RemainingRawTableBandExtent();

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => math.max(0.0, delegate.viewportExtent - delegate.precedingExtent);
}

/// Signature for a function that combines the result of two
/// [RawTableBandExtent.calculateExtent] invocations.
///
/// Used by [CombiningRawTableBandExtent.combiner];
typedef RawTableBandExtentCombiner = double Function(double, double);

/// Runs the result of two [RawTableBandExtent]s through a `combiner` function
/// to determine the ultimate pixel extent of a band.
class CombiningRawTableBandExtent extends RawTableBandExtent {
  /// Creates a [CombiningRawTableBandExtent];
  const CombiningRawTableBandExtent(this._spec1, this._spec2, this._combiner);

  final RawTableBandExtent _spec1;
  final RawTableBandExtent _spec2;
  final RawTableBandExtentCombiner _combiner;

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => _combiner(_spec1.calculateExtent(delegate), _spec2.calculateExtent(delegate));
}

/// Returns the larger pixel extent of the two provided [RawTableBandExtent].
class MaxRawTableBandExtent extends CombiningRawTableBandExtent {
  /// Creates a [MaxRawTableBandExtent].
  const MaxRawTableBandExtent(RawTableBandExtent spec1, RawTableBandExtent spec2) : super(spec1, spec2, math.max);
}

/// Returns the smaller pixel extent of the two provided [RawTableBandExtent].
class MinRawTableBandExtent extends CombiningRawTableBandExtent {
  /// Creates a [MinRawTableBandExtent].
  const MinRawTableBandExtent(RawTableBandExtent spec1, RawTableBandExtent spec2) : super(spec1, spec2, math.min);
}
