import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'framework_extensions.dart';
import 'dart_ui.dart';

class WindowController extends ChangeNotifier with WidgetsBindingObserver {
  WindowController({
    RelativeOffset? contentLocation,
    BoxConstraints? contentConstraints,
    bool? allowPointerEvents,
  }) : _initialConfigRequest = _createRequest(
    contentLocation,
    contentConstraints,
    allowPointerEvents,
  );

  bool get hasWindow => _flutterWindow != null;

  WindowConfiguration get window {
    if (!hasWindow) {
      throw Exception('Not connected to a window');
    }
    return _window!;
  }
  WindowConfiguration? _window;

  Future<void> requestUpdate({
    RelativeOffset? contentLocation,
    BoxConstraints? contentConstraints,
    bool? allowPointerEvents,
  }) async {
    if (!hasWindow) { // TODO: should it buffer requests?
      throw Exception('Not connected to a window');
    }
    final FlutterWindowRequest request = _createRequest(
      contentLocation,
      contentConstraints,
      allowPointerEvents,
    );
    return _flutterWindow?.requestUpdate(request);
  }

  @override
  void dispose() {
    if (_flutterWindow != null) {
      WidgetsBinding.instance.removeObserver(this);
      _flutterWindow?.close();
      _flutterWindow = null;
    }
    _attachedStates.clear();
    super.dispose();
  }

  // TODO: Should this have a close method?

  // TODO(goderbauer): should this update?
  final FlutterWindowRequest _initialConfigRequest;

  static FlutterWindowRequest _createRequest(
    RelativeOffset? contentLocation,
    BoxConstraints? contentConstraints,
    bool? allowPointerEvents,
  ) {
    final double devicePixelRatio = contentLocation?.devicePixelRatio ?? 1.0;
    return FlutterWindowRequest(
      contentLocation: contentLocation != null ? contentLocation * devicePixelRatio : null,
      contentConstraints: contentConstraints != null ? (contentConstraints * devicePixelRatio).toViewConstraints() : null,
      allowPointerEvents: allowPointerEvents,
    );
  }

  final Set<State<Window>> _attachedStates = <State<Window>>{};

  void _attach(State<Window> state) {
    assert(!_attachedStates.contains(state));
    _attachedStates.add(state);
    if (_attachedStates.length == 1) {
      _createWindow();
    }
  }

  bool _windowClosingScheduled = false;

  void _detach(State<Window> state) {
    assert(_attachedStates.contains(state));
    _attachedStates.remove(state);
    // Delay closing the window until the end of the frame in case another
    // State object is going to attach to this controller and wants to re-use
    // the window before then. In that case, we don't want to close it.
    if (_attachedStates.isEmpty && !_windowClosingScheduled) {
      _windowClosingScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        _windowClosingScheduled = false;
        if (_attachedStates.isEmpty) {
          _closeWindow();
        }
      });
    }
  }

  void _ensureWindow() {
    if (_flutterWindow != null) {
      _createWindow();
    }
  }

  FlutterWindow? _flutterWindow;
  bool _windowCreationPending = false;

  Future<void> _createWindow() async {
    assert(_flutterWindow == null);
    if (_windowCreationPending) {
      return;
    }
    _windowCreationPending = true;
    final FlutterWindow window = await WidgetsBinding.instance.platformDispatcher.createWindow(_initialConfigRequest);
    _windowCreationPending = false;
    if (_attachedStates.isEmpty) {
      // While the window was being created, all interested parties detached.
      window.close();
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _flutterWindow = window;
    _update();
  }

  void _closeWindow() {
    if (_flutterWindow != null) {
      WidgetsBinding.instance.removeObserver(this);
      _flutterWindow?.close();
      _flutterWindow = null;
      _update();
    }
  }

  void _update() {
    final WindowConfiguration? newWindow = _flutterWindow != null
        ? WindowConfiguration._fromFlutterWindow(_flutterWindow!)
        : null;
    if (newWindow != _window) {
      _window = newWindow;
      notifyListeners();
    }
  }

  @override // from WidgetsBindingObserver
  void didChangeWindows(Iterable<int> windowIds) {
    if (_flutterWindow == null || !windowIds.contains(_flutterWindow?.id)) {
      // Update doesn't concern window managed by this controller.
      return;
    }
    if (WidgetsBinding.instance.platformDispatcher.window(id: _flutterWindow!.id) == null) {
      // The window was closed.
      WidgetsBinding.instance.removeObserver(this);
      _flutterWindow = null;
    } // else: Some property on the window updated.
    _update();
  }
}

@immutable
class WindowConfiguration {
  const WindowConfiguration._({
    required this.view,
    required this.contentSize,
    required this.contentLocation,
    required this.contentConstraints,
    required this.devicePixelRatio,
    required this.display,
  });

  factory WindowConfiguration._fromFlutterWindow(FlutterWindow window) {
    final double devicePixelRatio = window.view.devicePixelRatio;

    return WindowConfiguration._(
      view: window.view,
      contentSize: window.contentSize / devicePixelRatio,
      contentLocation: window.contentLocation / devicePixelRatio,
      contentConstraints: BoxConstraints.fromViewConstraints(window.view.physicalConstraints) / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
      display: window.view.display,
    );
  }

  final FlutterView view;
  final Size contentSize;
  final RelativeOffset contentLocation;
  final BoxConstraints contentConstraints;
  final double devicePixelRatio;
  final Display display;
}

class Window extends StatefulWidget {
  const Window({
    super.key,
    this.controller,
    required this.onClosed,
    required this.child,
  });

  final WindowController? controller;
  final VoidCallback onClosed;
  final Widget child;

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> {
  static const Widget _placeholder = ViewCollection(views: <Widget>[]);

  WindowController get _effectiveController => widget.controller ?? _localController!;
  WindowController? _localController;
  bool _hasWindow = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _localController = WindowController();
    }
    _effectiveController
      ..addListener(_handleWindowChanged)
      .._attach(this);
    _hasWindow = _effectiveController.hasWindow;
  }

  @override
  void didUpdateWidget(Window oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _effectiveController
        ..removeListener(_handleWindowChanged)
        .._detach(this);
      if (widget.controller != null) {
        _localController?.dispose();
        _localController = null;
      } else {
        _localController ??= WindowController();
      }
      _effectiveController
        ..addListener(_handleWindowChanged)
        .._attach(this);
      _hasWindow = _effectiveController.hasWindow;
    }
  }

  @override
  void dispose() {
    _effectiveController
      ..removeListener(_handleWindowChanged)
      .._detach(this);
    _localController?.dispose();
    super.dispose();
  }

  void _handleWindowChanged() {
    if (_hasWindow != _effectiveController.hasWindow) {
      if (_hasWindow && !_effectiveController.hasWindow) {
        _didCloseWindow();
      }
      setState(() {
        _hasWindow = _effectiveController.hasWindow;
      });
    }
  }

  void _didCloseWindow() {
    assert(_hasWindow && !_effectiveController.hasWindow);
    widget.onClosed();
    // The expectation is that `widget.onClosed` removes the `Window` widget
    // from the widget tree and with that this `State` object gets unmounted and
    // disposed at the end of the next frame. However, if that contract is not
    // honored and the widget remains in the tree the code below creates a new
    // window to keep the windows in sync with the widget tree.
    ServicesBinding.instance.addPostFrameCallback((Duration timeStamp) {
      if (!mounted) {
        // Window widget was removed from the tree as expected, nothing to do here.
        return;
      }
      // Window widget was not removed from the widget tree. Create a new window
      // so windows and widget tree stay in sync.
      _effectiveController._ensureWindow();
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(_hasWindow == _effectiveController.hasWindow);
    return _WindowControllerScope(
      controller: _effectiveController,
      child: !_hasWindow
          ? _placeholder
          : View(
              view: _effectiveController.window.view,
              child: widget.child,
            ),
    );
  }
}

class _WindowControllerScope extends InheritedWidget {
  const _WindowControllerScope({required this.controller, required super.child});

  final WindowController? controller;

  @override
  bool updateShouldNotify(_WindowControllerScope oldWidget) => controller != oldWidget.controller;
}
