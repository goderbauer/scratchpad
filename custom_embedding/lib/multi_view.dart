// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  print(PlatformDispatcher.instance.views.first.devicePixelRatio);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: MultiWindowApp(),
    ),
  );
}

class MultiWindowApp extends StatefulWidget {
  const MultiWindowApp({Key? key}) : super(key: key);

  @override
  State<MultiWindowApp> createState() => _MultiWindowAppState();
}

class _MultiWindowAppState extends State<MultiWindowApp> {
  List<Widget> _views = [];

  void _onWindowCreated(int id) {
    final FlutterView view = PlatformDispatcher.instance.views
        .firstWhere((FlutterView v) => v.viewId == id);

    setState(() {
      _views = _views.toList()
        ..add(
          View(
            view: view,
            child: SubScreen(id: id),
          ),
        );
    });
    // print(_views);
  }

  @override
  void initState() {
    super.initState();
    final FlutterView view = PlatformDispatcher.instance.views.single;
    _views.add(
      View(
        view: view,
        child: MainScreen(
          onWindowCreated: _onWindowCreated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Collection(children: _views);
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key, required this.onWindowCreated}) : super(key: key);

  final Function onWindowCreated;

  static const MethodChannel channel = OptionalMethodChannel('flutter/window');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('I am the main screen.'),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () async {
              int id = await channel.invokeMethod('new');
              onWindowCreated(id);
            },
            child: Container(
              color: Colors.yellow,
              height: 50,
              width: 100,
              child: const Center(
                child: Text(
                  'new window',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
          )
        ],
      )),
    );
  }
}

class SubScreen extends StatelessWidget {
  const SubScreen({Key? key, required this.id}) : super(key: key);

  final int id;

  @override
  Widget build(BuildContext context) {
    [].insert
    return Container(
      color: Colors.yellow,
      child: Center(
        child: Text(
          'I am another window (id: $id).',
          style: const TextStyle(color: Colors.blue),
        ),
      ),
    );
  }
}
