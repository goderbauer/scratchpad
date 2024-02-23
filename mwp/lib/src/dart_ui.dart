// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

extension WindowApi on PlatformDispatcher {
  Iterable<FlutterWindow> get windows => _WindowManager.instance.windows;
  Future<FlutterWindow> createWindow(FlutterWindowRequest request) {
    return _WindowManager.instance.createWindow(request);
  }
  VoidCallback? get onWindowsChanged => _WindowManager.instance.onWindowsChanged;
  set onWindowsChanged(VoidCallback? value) {
    _WindowManager.instance.onWindowsChanged = value;
  }
}

// This should live on the PlatformDispatcher.
class _WindowManager {
  _WindowManager._() {
    _windowChannel.setMethodCallHandler(_handleChannelInvocation);
  }

  static _WindowManager get instance => _instance;
  static final _WindowManager _instance = _WindowManager._();

  Iterable<FlutterWindow> get windows => _windows.values;
  final Map<int, FlutterWindow> _windows = <int, FlutterWindow>{};

  Future<FlutterWindow> createWindow(FlutterWindowRequest request) async {
    final int? windowId = await _windowChannel.invokeMethod<int>('create', request._encode());
    if (windowId == null) {
      throw Exception('Unable to create window');
    }
    final FlutterWindow? window = _windows[windowId];
    if (window == null) {
      throw Exception('Unable to create window');
    }
    return window;
  }

  VoidCallback? onWindowsChanged;

  static const MethodChannel _windowChannel = MethodChannel('flutter/window');

  Future<Object?> _handleChannelInvocation(MethodCall call) async {
    bool invokeCallback = true;
    switch (call.method) {
      case 'update':
        final Map<String, Object> args = call.arguments as Map<String, Object>;
        final int windowId = args['id']! as int;
        final _FlutterWindowConfiguration config = _FlutterWindowConfiguration.decode(args['config']!);
        final FlutterView view = ServicesBinding.instance.platformDispatcher.view(id: config.viewId)!;
        final FlutterWindow? window = _windows[windowId];
        if (window != null) {
          window._update(config, view);
        } else {
          _windows[windowId] = FlutterWindow._(windowId, config, view);
        }
      case 'delete':
        invokeCallback = _windows.remove(call.arguments) != null;
    }
    if (invokeCallback) {
      onWindowsChanged?.call();
    }
    return null;
  }
}

class FlutterWindow {
  FlutterWindow._(this._id, this._config, this._view);

  final int _id;
  _FlutterWindowConfiguration _config;
  FlutterView _view;

  void _update(_FlutterWindowConfiguration config, FlutterView view) {
    _view = view;
    _config = config;
  }

  FlutterView get view => _view;
  Size get contentSize => _config.contentSize;

  Future<void> requestUpdate(FlutterWindowRequest request) async {
    await _WindowManager._windowChannel.invokeMethod('update', <String, Object?>{'id': _id, 'request': request._encode()});
  }

  Future<void> close() async {
    await _WindowManager._windowChannel.invokeMethod('close', _id);
  }
}

// Everything is in physical pixel!
@immutable
class FlutterWindowRequest {
  const FlutterWindowRequest({this.contentOffset, this.contentConstraints, this.allowPointerEvents});

  final RelativeOffset? contentOffset;
  final ViewConstraints? contentConstraints;
  final bool? allowPointerEvents;

  Object? _encode() {
    return <String, Object?>{
      'offset': contentOffset?._encode(),
      'constraint_min_width': contentConstraints?.minWidth,
      'constraint_max_width': contentConstraints?.maxWidth,
      'constraint_min_height': contentConstraints?.minHeight,
      'constraint_max_height': contentConstraints?.maxHeight,
      'pointerEvents': allowPointerEvents,
    };
  }
}

@immutable
class _FlutterWindowConfiguration {
  const _FlutterWindowConfiguration({
    required this.viewId,
    required this.contentSize,
    required this.contentOffset,
  });

  factory _FlutterWindowConfiguration.decode(Object encoded) {
    final Map<String, Object?> decoded = encoded as Map<String, Object?>;
    return _FlutterWindowConfiguration(
      viewId: decoded['viewId']! as int,
      contentSize: Size(decoded['width']! as double, decoded['height']! as double),
      contentOffset: RelativeOffset._decode(decoded['offset']!),
    );
  }

  final int viewId;
  final Size contentSize;
  final RelativeOffset contentOffset;
}

@immutable
class RelativeOffset {
  const RelativeOffset.display(Display this.display, this.offset) : view = null;
  const RelativeOffset.view(FlutterView this.view, this.offset) : display = null;

  factory RelativeOffset._decode(Object encoded) {
    final Map<String, Object?> decoded = encoded as Map<String, Object?>;
    final Offset offset = Offset(decoded['offset_x']! as double, decoded['offset_y']! as double);
    switch (decoded['type']) {
      case 'display':
        return RelativeOffset.display(
          ServicesBinding.instance.platformDispatcher.displays.firstWhere((Display d) => d.id == decoded['id']),
          offset,
        );
      case 'view':
        return RelativeOffset.view(
          ServicesBinding.instance.platformDispatcher.view(id: decoded['id']! as int)!,
          offset,
        );
      default:
        throw Exception();
    }
  }

  final FlutterView? view;
  final Display? display;
  final Offset offset;

  double get devicePixelRatio => view?.devicePixelRatio ?? display?.devicePixelRatio ?? 1.0;

  Object _encode() {
    return <String, Object?>{
      'type': view == null ? 'display' : 'view',
      'id': view?.viewId ?? display?.id,
      'offset_x': offset.dx,
      'offset_y': offset.dy,
    };
  }
}
