import 'package:flutter/material.dart';

import 'src/macro.dart';

void main() {
  runApp(const App(name: 'Dash'));
}

@Stateless()
class App {
  @Input() String get name;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Counter(
        name: name,
        startValue: 10,
      ),
    );
  }
}

@Stateful()
class Counter {
  // TODO: How to specify initializer asserts?
  @Input() String get name;
  @Input(0) int get startValue;

  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hello $name')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _count += 1;
          });
        },
      ),
      body: Center(
        child: Text('Count: ${startValue + _count}'),
      ),
    );
  }
}
