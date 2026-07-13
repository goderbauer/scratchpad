# Ephemeral

A Flutter package and demonstration for dynamically executing JavaScript bundles that produce **A2UI** (Agent-to-User Interface) descriptions and rendering them natively using `package:genui`.

---

## What is Ephemeral?

`Ephemeral` is a Flutter widget that allows mobile, desktop, and web applications to download or load standalone JavaScript bundles at runtime. The JavaScript code returns an A2UI JSON description of the user interface, which `Ephemeral` inflates into native Flutter components via `package:genui`.

Key capabilities:
- **Runtime Remote UI**: Load JS bundles dynamically from network URLs (`Ephemeral.network`) or asset bundles (`Ephemeral.asset`).
- **Interactive UI Event Bridge**: Captures UI events (e.g. button presses) on rendered A2UI components and dispatches them back to the JS runtime environment.
- **Flutter-like Dart Framework for JS**: Write remote UI bundles in pure Dart using `StatefulWidget`, `StatelessWidget`, and `setState()`, compiled to JavaScript using `dart compile js --server-mode`.

---

## How It Works

```
┌─────────────────────────────────┐           ┌──────────────────────────────────┐
│         Flutter App             │           │        JS Runtime (flutter_js)   │
│                                 │           │                                  │
│  Ephemeral Widget               │  render() │  render()                        │
│  ├─► calls render() in JS ─────┼──────────►├─► generates A2UI UI description  │
│  ├─► parses A2UI JSON payload   │◄──────────┤   (JSON components & state)      │
│  └─► renders via package:genui  │  JSON UI  └──────────────────────────────────┘
│                                 │                            ▲
│  User Taps Button               │                            │
│  └─► captures UI Event ─────────┼───────────► onUIEvent() ───┘
│                                 │               │
│  setState() ◄───────────────────┼───────────────┘ rebuild()
└─────────────────────────────────┘
```

1. **JS Loading & Execution**: The `Ephemeral` widget initializes a `flutter_js` JavaScript runtime, loading the JS script from a URL or asset path.
2. **Synchronous `render()`**: During Flutter's `build()` cycle, `Ephemeral` calls the global `render()` function in the JS engine to retrieve the current A2UI JSON representation.
3. **GenUI Surface Rendering**: `Ephemeral` parses `A2uiMessage` instances (`CreateSurface`, `UpdateComponents`, `UpdateDataModel`) and passes them to `SurfaceController`, rendering the UI.
4. **Event Dispatching & Rebuilding**: When a user interacts with a rendered component (such as tapping a button), the event is dispatched to `onUIEvent(eventData)` in the JS runtime. Invoking `setState()` inside the JS bundle calls `rebuild()`, notifying `Ephemeral` to trigger a Flutter re-render.

---

## A2UI Dart Mini-Framework

You can write your JS UI bundles in Dart using `bin/a2ui_framework.dart`, which provides a familiar Flutter-like API:

```dart
import 'a2ui_framework.dart';

void main() {
  runWidget(const CounterApp(), surfaceId: 'counter');
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Text('Counter App', variant: 'h2'),
          Text('Current count: $count', variant: 'h3'),
          Row(
            children: [
              Button(
                onPressed: () => setState(() => count--),
                child: const Text('Decrement (-)'),
              ),
              Button(
                onPressed: () => setState(() => count++),
                child: const Text('Increment (+)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Getting Started

### 1. Compile the Counter App to JS

To compile the Dart counter app (`bin/counter.dart`) into the JavaScript bundle asset (`assets/counter.js`), run:

```bash
./tool/compile_counter.sh
```

### 2. Run the HTTP Demo App

First, start a Python HTTP web server inside the `assets/` directory to serve `counter.js` on `http://localhost:8000`:

```bash
python3 -m http.server 8000 --directory assets
```

Then, run the demo app which loads JS bundles remotely from a URL (includes force-reload from server):

```bash
flutter run --release -t lib/main_http.dart
```

> **Note**: You can edit `bin/counter.dart`, recompile it with `./tool/compile_counter.sh`, and tap the reload button in the app to fetch and render the updated module live without restarting the application.

