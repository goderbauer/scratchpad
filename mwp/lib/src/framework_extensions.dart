import 'dart:ui';

import 'package:flutter/rendering.dart';

// TODO: everything in this file should be added to the framework.

extension BoxConstraintsExtension on BoxConstraints {
  /// Creates [ViewConstraints] that matches this box constraints.
  ViewConstraints toViewConstraints() {
    return ViewConstraints(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight);
  }
}
