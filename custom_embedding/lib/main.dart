import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _counter = 0;

  static const MethodChannel channel = OptionalMethodChannel('flutter/window');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    print('metrics changed');
    setState(() {
      // WidgetsBinding.instance.platformDispatcher.views changed.
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    // print(' >>>>> ${WidgetsBinding.instance.platformDispatcher.views}');
    // print(MediaQuery.of(context).size);
  }

  Object selectedViewId = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<Object>(
                  value: selectedViewId,
                  items: WidgetsBinding.instance.platformDispatcher.views.map((FlutterView view) {
                    return DropdownMenuItem<Object>(
                      value: view.viewId,
                      child: Text(view.toString()),
                    );
                  }).toList(),
                  onChanged: (Object? viewId) {
                    setState(() {
                      selectedViewId = viewId!;
                    });
                  },
                ),
                TextButton(
                  child: const Text('Switch'),
                  onPressed: () {
                    context.findAncestorStateOfType<MediaQueryFromWindowState>()!.selectView(selectedViewId);
                  },
                ),
                TextButton(
                  child: const Text('Open'),
                  onPressed: () async {
                    int id = await channel.invokeMethod('new');
                    print('NEW WINDOW: $id');
                  },
                ),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
