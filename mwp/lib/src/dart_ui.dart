// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

extension WindowApi on PlatformDispatcher {
  Iterable<FlutterWindow> get windows => _WindowManager.instance.windows;
  FlutterWindow? window({required int id}) => _WindowManager.instance.window(id: id);
  Future<FlutterWindow> createWindow(FlutterWindowRequest request) {
    return _WindowManager.instance.createWindow(request);
  }
  WindowsChangedCallback? get onWindowsChanged => _WindowManager.instance.onWindowsChanged;
  set onWindowsChanged(WindowsChangedCallback? value) {
    _WindowManager.instance.onWindowsChanged = value;
  }
}

typedef WindowsChangedCallback = void Function(Iterable<int> windowIds);

// This should live on the PlatformDispatcher.
class _WindowManager {
  _WindowManager._() {
    _windowChannel.setMethodCallHandler(_handleChannelInvocation);
  }

  static _WindowManager get instance => _instance;
  static final _WindowManager _instance = _WindowManager._();

  Iterable<FlutterWindow> get windows => _windows.values;
  final Map<int, FlutterWindow> _windows = <int, FlutterWindow>{};

  FlutterWindow? window({required int id}) => _windows[id];

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

  WindowsChangedCallback? onWindowsChanged;

  static const MethodChannel _windowChannel = MethodChannel('flutter/window');

  Future<Object?> _handleChannelInvocation(MethodCall call) async {
    final List<int> ids = <int>[];
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
        ids.add(windowId);
      case 'delete':
        final int windowId = call.arguments as int;
        if (_windows.remove(windowId) != null) {
          ids.add(windowId);
        }
    }
    if (ids.isNotEmpty) {
      onWindowsChanged?.call(ids);
    }
    return null;
  }
}

class FlutterWindow {
  FlutterWindow._(this.id, this._config, this._view);

  final int id;
  _FlutterWindowConfiguration _config;
  FlutterView _view;

  void _update(_FlutterWindowConfiguration config, FlutterView view) {
    _view = view;
    _config = config;
  }

  FlutterView get view => _view;
  Size get contentSize => _config.contentSize;
  RelativeOffset get contentLocation => _config.contentLocation;

  Future<void> requestUpdate(FlutterWindowRequest request) async {
    await _WindowManager._windowChannel.invokeMethod('update', <String, Object?>{'id': id, 'request': request._encode()});
  }

  Future<void> close() async {
    await _WindowManager._windowChannel.invokeMethod('close', id);
  }
}

// Everything is in physical pixel!
@immutable
class FlutterWindowRequest {
  const FlutterWindowRequest({
    this.contentLocation,
    this.contentConstraints,
    this.allowPointerEvents,
  });

  final RelativeOffset? contentLocation;
  final ViewConstraints? contentConstraints;
  final bool? allowPointerEvents;

  Object? _encode() {
    return <String, Object?>{
      'location': contentLocation?._encode(),
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
    required this.contentLocation,
  });

  factory _FlutterWindowConfiguration.decode(Object encoded) {
    final Map<String, Object?> decoded = encoded as Map<String, Object?>;
    return _FlutterWindowConfiguration(
      viewId: decoded['viewId']! as int,
      contentSize: Size(decoded['width']! as double, decoded['height']! as double),
      contentLocation: RelativeOffset._decode(decoded['offset']!),
    );
  }

  final int viewId;
  final Size contentSize;
  final RelativeOffset contentLocation;
}

@immutable
class RelativeOffset {
  const RelativeOffset.display(Display this.display, this.offset) : view = null;
  const RelativeOffset.view(FlutterView this.view, this.offset) : display = null;
  const RelativeOffset._(this.view, this.display, this.offset) : assert(view ==null || display == null);

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

  RelativeOffset operator *(double operand) => RelativeOffset._(view, display, offset * operand);
  RelativeOffset operator /(double operand) => RelativeOffset._(view, display, offset / operand);

  Object _encode() {
    return <String, Object?>{
      'type': view == null ? 'display' : 'view',
      'id': view?.viewId ?? display?.id,
      'offset_x': offset.dx,
      'offset_y': offset.dy,
    };
  }
}
