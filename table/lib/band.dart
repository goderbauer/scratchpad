import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:table/band_decoration.dart';

class RawTableBand {
  const RawTableBand({
    required this.extent,
    this.recognizerFactories = const <Type, GestureRecognizerFactory>{},
    this.onEnter,
    this.onExit,
    this.cursor = MouseCursor.defer,
    this.decoration,
  });

  // ---- Sizing ----
  final RawTableBandExtent extent;

  // ---- Gestures & Mouse ----
  final Map<Type, GestureRecognizerFactory> recognizerFactories;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final MouseCursor cursor;
  final RawTableBandDecoration? decoration;
}

class RawTableBandExtentDelegate {
  const RawTableBandExtentDelegate({required this.viewportExtent, required this.precedingExtent});

  final double viewportExtent;
  final double precedingExtent;
}

abstract class RawTableBandExtent {
  const RawTableBandExtent();

  double calculateExtent(RawTableBandExtentDelegate delegate);
}

class FixedRawTableBandExtent extends RawTableBandExtent {
  const FixedRawTableBandExtent(this.pixels) : assert(pixels >= 0.0);

  final double pixels;

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => pixels;
}

class FractionalRawTableBandExtent extends RawTableBandExtent {
  const FractionalRawTableBandExtent(this.fraction) : assert(fraction >= 0.0);

  final double fraction;

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => delegate.viewportExtent * fraction;
}

class RemainingRawTableBandExtent extends RawTableBandExtent {
  const RemainingRawTableBandExtent();

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => math.max(0.0, delegate.viewportExtent - delegate.precedingExtent);
}

typedef RawTableBandExtentCombiner = double Function(double, double);

class CombiningRawTableBandExtent extends RawTableBandExtent {
  const CombiningRawTableBandExtent(this.spec1, this.spec2, this.combiner);

  final RawTableBandExtent spec1;
  final RawTableBandExtent spec2;
  final RawTableBandExtentCombiner combiner;

  @override
  double calculateExtent(RawTableBandExtentDelegate delegate) => combiner(spec1.calculateExtent(delegate), spec2.calculateExtent(delegate));
}

class MaxTableDimensionSpec extends CombiningRawTableBandExtent {
  const MaxTableDimensionSpec(RawTableBandExtent spec1, RawTableBandExtent spec2) : super(spec1, spec2, math.max);
}

class MinTableDimensionSpec extends CombiningRawTableBandExtent {
  const MinTableDimensionSpec(RawTableBandExtent spec1, RawTableBandExtent spec2) : super(spec1, spec2, math.min);
}
