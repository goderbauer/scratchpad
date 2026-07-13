import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;

/// A Flutter widget that fetches a JavaScript file from a URL or loads it from
/// an asset bundle, executes it using `flutter_js`, and renders the resulting
/// A2UI JSON UI description using `package:genui`.
class Ephemeral extends StatefulWidget {
  /// Creates an [Ephemeral] widget that loads JS from a network [url].
  const Ephemeral({
    super.key,
    required this.url,
    this.catalog,
    this.client,
    this.loadingBuilder,
    this.errorBuilder,
    this.enableJsXHR = false,
    this.onUiEvent,
  })  : assetPath = null,
        assetBundle = null;

  /// Creates an [Ephemeral] widget that loads JS from a network [url].
  const Ephemeral.network({
    super.key,
    required this.url,
    this.catalog,
    this.client,
    this.loadingBuilder,
    this.errorBuilder,
    this.enableJsXHR = false,
    this.onUiEvent,
  })  : assetPath = null,
        assetBundle = null;

  /// Creates an [Ephemeral] widget that loads JS from an asset specified by [assetPath].
  const Ephemeral.asset({
    super.key,
    required this.assetPath,
    this.assetBundle,
    this.catalog,
    this.loadingBuilder,
    this.errorBuilder,
    this.enableJsXHR = false,
    this.onUiEvent,
  })  : url = null,
        client = null;

  /// The URL pointing to the JS file to download and execute.
  final Uri? url;

  /// The path of the asset containing the JS file to execute.
  final String? assetPath;

  /// An optional [AssetBundle] to load [assetPath] from.
  final AssetBundle? assetBundle;

  /// The [Catalog] of components available to render the A2UI description.
  /// Defaults to [BasicCatalogItems.asCatalog()] if omitted.
  final Catalog? catalog;

  /// An optional [http.Client] used for downloading the JS file.
  /// If omitted, a standard [http.Client] will be created.
  final http.Client? client;

  /// Optional widget builder displayed while fetching or executing the JS code.
  final WidgetBuilder? loadingBuilder;

  /// Optional widget builder displayed when an error occurs during fetch or execution.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )? errorBuilder;

  /// Whether to enable XHR in `flutter_js`. Defaults to false.
  final bool enableJsXHR;

  /// Optional callback when a UI interaction event (e.g. button press) occurs.
  final void Function(String interactionJson)? onUiEvent;

  @override
  State<Ephemeral> createState() => _EphemeralState();
}

class _EphemeralState extends State<Ephemeral> {
  JavascriptRuntime? _jsRuntime;
  JsEvalResult? _initialEvalResult;
  SurfaceController? _surfaceController;
  StreamSubscription<ChatMessage>? _onSubmitSubscription;

  bool _isLoading = true;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _loadAndExecute();
  }

  @override
  void didUpdateWidget(Ephemeral oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url ||
        widget.assetPath != oldWidget.assetPath ||
        widget.assetBundle != oldWidget.assetBundle) {
      _loadAndExecute();
    }
  }

  Future<void> _loadAndExecute() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _stackTrace = null;
    });

    try {
      // 1. Fetch JS file content from Asset or Network URL
      final String jsCode;
      if (widget.assetPath != null) {
        final bundle = widget.assetBundle ?? rootBundle;
        jsCode = await bundle.loadString(widget.assetPath!);
      } else if (widget.url != null) {
        final client = widget.client ?? http.Client();
        final response = await client.get(
          widget.url!,
          headers: const {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        );
        if (response.statusCode != 200) {
          throw Exception(
            'Failed to load JS file from ${widget.url} '
            '(Status ${response.statusCode}: ${response.reasonPhrase})',
          );
        }
        jsCode = response.body;
      } else {
        throw Exception(
          'Neither url nor assetPath was provided to Ephemeral widget',
        );
      }

      // 2. Initialize JavascriptRuntime and register 'rebuild' channel callback
      _jsRuntime?.dispose();
      final runtime = getJavascriptRuntime(xhr: widget.enableJsXHR);
      _jsRuntime = runtime;

      runtime.onMessage('rebuild', (dynamic args) {
        Future.microtask(() {
          if (mounted) {
            setState(() {});
          }
        });
      });

      runtime.evaluate('''
(function() {
  globalThis.rebuild = function() {
    if (typeof sendMessage === 'function') {
      setTimeout(function() {
        sendMessage('rebuild', 'true');
      }, 0);
    }
  };
  globalThis.requestRebuild = globalThis.rebuild;
  globalThis.requestRender = globalThis.rebuild;
})()
''');

      var evalResult = runtime.evaluate(jsCode);
      if (evalResult.isPromise ||
          evalResult.stringResult == '[object Promise]') {
        evalResult = await runtime.handlePromise(evalResult);
      }

      if (evalResult.isError) {
        throw Exception('Error executing JS code: ${evalResult.stringResult}');
      }
      _initialEvalResult = evalResult;

      // 3. Setup SurfaceController and listen for UI interaction events
      final catalog = widget.catalog ?? BasicCatalogItems.asCatalog();
      _onSubmitSubscription?.cancel();
      _surfaceController?.dispose();
      final controller = SurfaceController(catalogs: [catalog]);
      _surfaceController = controller;

      _onSubmitSubscription =
          controller.onSubmit.listen((ChatMessage message) async {
            for (final part in message.parts) {
              final interaction = part.asUiInteractionPart?.interaction;
              if (interaction != null) {
                debugPrint('Ephemeral UI event: $interaction');
                widget.onUiEvent?.call(interaction);

                final currentRuntime = _jsRuntime;
                if (currentRuntime != null) {
                  try {
                    final String evalCode = '''
(function() {
  if (typeof onUIEvent === 'function') {
    var eventData;
    try {
      eventData = JSON.parse(${jsonEncode(interaction)});
    } catch (e) {
      eventData = ${jsonEncode(interaction)};
    }
    onUIEvent(eventData);
  }
})()
''';
                    var resEval = currentRuntime.evaluate(evalCode);
                    if (resEval.isPromise ||
                        resEval.stringResult == '[object Promise]') {
                      await currentRuntime.handlePromise(resEval);
                    }
                  } catch (e, st) {
                    debugPrint('Error executing onUIEvent in JS: $e\n$st');
                  }
                }
              }
            }
          });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = e;
          _stackTrace = st;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _stackTrace);
      }
      return ErrorWidget(_error!);
    }

    if (_jsRuntime == null || _surfaceController == null) {
      return const SizedBox.shrink();
    }

    String? activeId;
    try {
      // Synchronously call `render()` in JS to retrieve latest A2UI definition
      const String renderJs = '''
(function() {
  if (typeof render === 'function') {
    var res = render();
    if (typeof res === 'string') return res;
    if (res !== undefined && res !== null) return JSON.stringify(res);
  }
  return null;
})()
''';
      var evalResult = _jsRuntime!.evaluate(renderJs);
      if (evalResult.isError) {
        throw Exception(
          'Error executing JS render(): ${evalResult.stringResult}',
        );
      }

      String rawResult = evalResult.stringResult;
      if (rawResult == 'null' ||
          rawResult == 'undefined' ||
          rawResult.isEmpty) {
        final initial = _initialEvalResult;
        if (initial != null) {
          rawResult = initial.stringResult;
          if (rawResult == '[object Object]' || rawResult == '[object Array]') {
            try {
              rawResult = _jsRuntime!.jsonStringify(initial);
            } catch (_) {}
          }
        }
      } else if (rawResult == '[object Object]' ||
          rawResult == '[object Array]') {
        try {
          rawResult = _jsRuntime!.jsonStringify(evalResult);
        } catch (_) {}
      }

      if (rawResult.isNotEmpty &&
          rawResult != 'null' &&
          rawResult != 'undefined') {
        dynamic jsonPayload = jsonDecode(rawResult);
        if (jsonPayload is String) {
          jsonPayload = jsonDecode(jsonPayload);
        }

        final List<A2uiMessage> messages = [];
        if (jsonPayload is List) {
          for (final item in jsonPayload) {
            if (item is Map<String, dynamic>) {
              messages.add(A2uiMessage.fromJson(item));
            }
          }
        } else if (jsonPayload is Map<String, dynamic>) {
          messages.add(A2uiMessage.fromJson(jsonPayload));
        }

        final catalog = widget.catalog ?? BasicCatalogItems.asCatalog();
        final bool hasCreateSurface = messages.any((m) => m is CreateSurface);
        if (!hasCreateSurface) {
          for (final msg in messages) {
            if (msg is UpdateComponents) {
              activeId = msg.surfaceId;
              _surfaceController!.handleMessage(
                CreateSurface(
                  surfaceId: msg.surfaceId,
                  catalogId: catalog.catalogId ?? basicCatalogId,
                ),
              );
              break;
            }
          }
        }

        for (final msg in messages) {
          if (msg is CreateSurface) {
            activeId = msg.surfaceId;
          } else if (msg is UpdateComponents && activeId == null) {
            activeId = msg.surfaceId;
          }
          _surfaceController!.handleMessage(msg);
        }

        activeId ??= _surfaceController!.activeSurfaceIds.firstOrNull;
      }
    } catch (e, st) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, e, st);
      }
      return ErrorWidget(e);
    }

    if (activeId == null) {
      return const SizedBox.shrink();
    }

    return Surface(
      surfaceContext: _surfaceController!.contextFor(activeId),
    );
  }

  @override
  void dispose() {
    _onSubmitSubscription?.cancel();
    _jsRuntime?.dispose();
    _surfaceController?.dispose();
    super.dispose();
  }
}
