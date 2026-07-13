import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('rebuild')
external void rebuild();

/// Abstract BuildContext interface matching Flutter convention.
abstract class BuildContext {}

/// Base class for all A2UI widgets.
abstract class Widget {
  const Widget({this.key});
  final String? key;

  Element createElement();

  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType &&
        oldWidget.key == newWidget.key;
  }
}

/// Abstract Element node in the widget tree.
abstract class Element implements BuildContext {
  Element(this.widget);

  Widget widget;
  Element? parent;

  void mount(Element? parent) {
    this.parent = parent;
  }

  void update(Widget newWidget) {
    widget = newWidget;
  }

  void rebuildElement();

  String render(A2uiRenderContext context);

  List<Element> get childrenElements;
}

/// Context for assigning component IDs and building component lists.
class A2uiRenderContext {
  final List<Map<String, dynamic>> components = [];
  final Map<String, void Function()> actionHandlers = {};
  int _counter = 0;

  String nextId([String? requestedId]) {
    if (requestedId != null && requestedId.isNotEmpty) return requestedId;
    if (_counter == 0) {
      _counter++;
      return 'root';
    }
    return 'node_${_counter++}';
  }

  void registerActionHandler(String actionName, void Function() handler) {
    actionHandlers[actionName] = handler;
  }
}

/// A widget that does not require mutable state.
abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});

  @override
  Element createElement() => StatelessElement(this);

  Widget build(BuildContext context);
}

class StatelessElement extends Element {
  StatelessElement(super.widget);

  Element? child;

  @override
  List<Element> get childrenElements => child != null ? [child!] : [];

  @override
  void mount(Element? parent) {
    super.mount(parent);
    rebuildElement();
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    rebuildElement();
  }

  @override
  void rebuildElement() {
    final builtWidget = (widget as StatelessWidget).build(this);
    if (child == null) {
      child = builtWidget.createElement();
      child!.mount(this);
    } else if (Widget.canUpdate(child!.widget, builtWidget)) {
      child!.update(builtWidget);
    } else {
      child = builtWidget.createElement();
      child!.mount(this);
    }
  }

  @override
  String render(A2uiRenderContext context) {
    return child!.render(context);
  }
}

/// A widget that has mutable state.
abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});

  @override
  Element createElement() => StatefulElement(this);

  State createState();
}

/// Logic and state for a [StatefulWidget].
abstract class State<T extends StatefulWidget> {
  late T widget;
  late BuildContext context;
  late StatefulElement _element;

  Widget build(BuildContext context);

  void setState(void Function() fn) {
    fn();
    _element.rebuildElement();
    rebuild();
  }
}

class StatefulElement extends Element {
  StatefulElement(super.widget);

  late final State state;
  Element? child;

  @override
  List<Element> get childrenElements => child != null ? [child!] : [];

  @override
  void mount(Element? parent) {
    super.mount(parent);
    state = (widget as StatefulWidget).createState();
    state.widget = widget as StatefulWidget;
    state.context = this;
    state._element = this;
    rebuildElement();
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    state.widget = newWidget as StatefulWidget;
    rebuildElement();
  }

  @override
  void rebuildElement() {
    final builtWidget = state.build(this);
    if (child == null) {
      child = builtWidget.createElement();
      child!.mount(this);
    } else if (Widget.canUpdate(child!.widget, builtWidget)) {
      child!.update(builtWidget);
    } else {
      child = builtWidget.createElement();
      child!.mount(this);
    }
  }

  @override
  String render(A2uiRenderContext context) {
    return child!.render(context);
  }
}

/// Primitive Leaf Widgets that map directly to A2UI components.
abstract class LeafWidget extends Widget {
  const LeafWidget({super.key});
}

abstract class SingleChildLeafWidget extends LeafWidget {
  const SingleChildLeafWidget({super.key, this.child});
  final Widget? child;

  @override
  Element createElement() => SingleChildLeafElement(this);
}

class SingleChildLeafElement extends Element {
  SingleChildLeafElement(super.widget);

  Element? child;

  @override
  List<Element> get childrenElements => child != null ? [child!] : [];

  @override
  void mount(Element? parent) {
    super.mount(parent);
    final w = widget as SingleChildLeafWidget;
    if (w.child != null) {
      child = w.child!.createElement();
      child!.mount(this);
    }
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    final w = newWidget as SingleChildLeafWidget;
    if (child == null && w.child != null) {
      child = w.child!.createElement();
      child!.mount(this);
    } else if (child != null &&
        w.child != null &&
        Widget.canUpdate(child!.widget, w.child!)) {
      child!.update(w.child!);
    } else if (w.child != null) {
      child = w.child!.createElement();
      child!.mount(this);
    } else {
      child = null;
    }
  }

  @override
  void rebuildElement() {}

  @override
  String render(A2uiRenderContext context) {
    final id = context.nextId(widget.key);
    final childId = child?.render(context);
    final map = <String, dynamic>{
      'id': id,
      'component': _componentName,
    };
    if (childId != null) {
      map['child'] = childId;
    }
    if (widget is Button) {
      final btn = widget as Button;
      if (btn.onPressed != null) {
        final actionName = 'action_$id';
        context.registerActionHandler(actionName, btn.onPressed!);
        map['action'] = {
          'event': {'name': actionName},
        };
      }
    }
    context.components.add(map);
    return id;
  }

  String get _componentName {
    if (widget is Card) return 'Card';
    if (widget is Button) return 'Button';
    return widget.runtimeType.toString();
  }
}

abstract class MultiChildLeafWidget extends LeafWidget {
  const MultiChildLeafWidget({super.key, required this.children});
  final List<Widget> children;

  @override
  Element createElement() => MultiChildLeafElement(this);
}

class MultiChildLeafElement extends Element {
  MultiChildLeafElement(super.widget);

  final List<Element> children = [];

  @override
  List<Element> get childrenElements => children;

  @override
  void mount(Element? parent) {
    super.mount(parent);
    final w = widget as MultiChildLeafWidget;
    for (final childWidget in w.children) {
      final elem = childWidget.createElement();
      elem.mount(this);
      children.add(elem);
    }
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    final w = newWidget as MultiChildLeafWidget;
    final newChildren = <Element>[];
    for (var i = 0; i < w.children.length; i++) {
      final newW = w.children[i];
      if (i < children.length && Widget.canUpdate(children[i].widget, newW)) {
        children[i].update(newW);
        newChildren.add(children[i]);
      } else {
        final elem = newW.createElement();
        elem.mount(this);
        newChildren.add(elem);
      }
    }
    children.clear();
    children.addAll(newChildren);
  }

  @override
  void rebuildElement() {}

  @override
  String render(A2uiRenderContext context) {
    final id = context.nextId(widget.key);
    final childIds = <String>[];
    for (final child in children) {
      childIds.add(child.render(context));
    }
    final map = <String, dynamic>{
      'id': id,
      'component': _componentName,
      'children': childIds,
    };
    context.components.add(map);
    return id;
  }

  String get _componentName {
    if (widget is Column) return 'Column';
    if (widget is Row) return 'Row';
    return widget.runtimeType.toString();
  }
}

/// A2UI Card Leaf Widget
class Card extends SingleChildLeafWidget {
  const Card({super.key, super.child});
}

/// A2UI Column Leaf Widget
class Column extends MultiChildLeafWidget {
  const Column({super.key, required super.children});
}

/// A2UI Row Leaf Widget
class Row extends MultiChildLeafWidget {
  const Row({super.key, required super.children});
}

/// A2UI Text Leaf Widget
class Text extends LeafWidget {
  const Text(this.text, {super.key, this.variant});
  final dynamic text;
  final String? variant;

  @override
  Element createElement() => TextLeafElement(this);
}

class TextLeafElement extends Element {
  TextLeafElement(super.widget);

  @override
  List<Element> get childrenElements => const [];

  @override
  void rebuildElement() {}

  @override
  String render(A2uiRenderContext context) {
    final w = widget as Text;
    final id = context.nextId(w.key);
    final map = <String, dynamic>{
      'id': id,
      'component': 'Text',
      'text': w.text,
    };
    if (w.variant != null) {
      map['variant'] = w.variant;
    }
    context.components.add(map);
    return id;
  }
}

/// A2UI Button Leaf Widget
class Button extends SingleChildLeafWidget {
  const Button({
    super.key,
    this.onPressed,
    required Widget child,
  }) : super(child: child);

  final void Function()? onPressed;
}

/// App Runner for maintaining the Element Tree and generating A2UI JSON payload.
class A2uiApp {
  A2uiApp(this.rootWidget) {
    rootElement = rootWidget.createElement();
    rootElement.mount(null);
  }

  final Widget rootWidget;
  late final Element rootElement;
  Map<String, void Function()> _actionHandlers = {};

  String renderSurface({required String surfaceId}) {
    final renderContext = A2uiRenderContext();
    rootElement.render(renderContext);
    _actionHandlers = renderContext.actionHandlers;

    final payload = [
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': 'https://a2ui.org/specification/v0_9/basic_catalog.json',
          'sendDataModel': true,
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': renderContext.components,
        },
      },
    ];
    return jsonEncode(payload);
  }

  void handleUIEvent(Map<String, dynamic> event) {
    final action = event['action'];
    if (action is Map) {
      final actionName = action['name'];
      if (actionName is String) {
        final handler = _actionHandlers[actionName];
        handler?.call();
      }
    }
  }
}

late final A2uiApp _app;
late final String _surfaceId;

JSString _render() {
  return _app.renderSurface(surfaceId: _surfaceId).toJS;
}

void _onUIEvent(JSAny? event) {
  final eventDart = event?.dartify();
  if (eventDart is Map<String, dynamic>) {
    _app.handleUIEvent(eventDart);
  } else if (eventDart is Map) {
    _app.handleUIEvent(Map<String, dynamic>.from(eventDart));
  }
}

/// Inflates [widget] into an Element tree and exposes `render` and `onUIEvent` to JavaScript.
void runWidget(Widget widget, {String surfaceId = 'counter'}) {
  _surfaceId = surfaceId;
  _app = A2uiApp(widget);
  globalContext.setProperty('render'.toJS, _render.toJS);
  globalContext.setProperty('onUIEvent'.toJS, _onUIEvent.toJS);
}
