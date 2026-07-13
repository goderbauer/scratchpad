import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

int count = 0;

JSString render() {
  final payload = [
    {
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'counter',
        'catalogId': 'https://a2ui.org/specification/v0_9/basic_catalog.json',
        'sendDataModel': true,
      },
    },
    {
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'counter',
        'components': [
          {'id': 'root', 'component': 'Card', 'child': 'main_column'},
          {
            'id': 'main_column',
            'component': 'Column',
            'children': ['title', 'count_display', 'button_row'],
          },
          {
            'id': 'title',
            'component': 'Text',
            'text': 'Counter App',
            'variant': 'h2',
          },
          {
            'id': 'count_display',
            'component': 'Text',
            'text': {'path': '/count'},
            'variant': 'h3',
          },
          {
            'id': 'button_row',
            'component': 'Row',
            'children': ['decrement_btn', 'increment_btn'],
          },
          {
            'id': 'decrement_btn',
            'component': 'Button',
            'child': 'decrement_label',
            'action': {
              'event': {'name': 'decrement'},
            },
          },
          {
            'id': 'decrement_label',
            'component': 'Text',
            'text': 'Decrement (-)',
          },
          {
            'id': 'increment_btn',
            'component': 'Button',
            'child': 'increment_label',
            'action': {
              'event': {'name': 'increment'},
            },
          },
          {
            'id': 'increment_label',
            'component': 'Text',
            'text': 'Increment (+)',
          },
        ],
      },
    },
    {
      'version': 'v0.9',
      'updateDataModel': {
        'surfaceId': 'counter',
        'path': '/count',
        'value': 'Current count: $count',
      },
    },
  ];
  return jsonEncode(payload).toJS;
}

JSBoolean onUIEvent(JSAny? event) {
  final eventDart = event?.dartify();
  if (eventDart is Map) {
    final action = eventDart['action'];
    if (action is Map) {
      final actionName = action['name'];
      if (actionName == 'increment') {
        count += 5;
        return true.toJS;
      } else if (actionName == 'decrement') {
        count--;
        return true.toJS;
      }
    }
  }
  return false.toJS;
}

void main() {
  globalContext.setProperty('render'.toJS, render.toJS);
  globalContext.setProperty('onUIEvent'.toJS, onUIEvent.toJS);
}
