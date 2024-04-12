import 'package:flutter/material.dart';

import 'src/macro.dart';

void main() {
  runApp(const App(name: 'Michael'));
}

@Stateless() // TODO: would be nice if this could be @statelessWidget instead.
// TODO: fix lint, https://github.com/dart-lang/linter/issues/4936
// ignore: use_key_in_widget_constructors
class App extends StatelessWidget { // TODO: The macro should add "extends StatelessWidget", https://github.com/dart-lang/sdk/issues/55425
  @Input() String? get name;

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

@Stateful() // TODO: would be nice if this could be @statefulWidget instead.
class Counter extends State { // TODO: The macro should add "extends State", https://github.com/dart-lang/sdk/issues/55425
  // TODO: How to specify default values and initializer asserts?
  @Input() String? get name;
  @Input() int? get startValue;

  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hello ${name ?? ''}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _count += 1;
          });
        },
      ),
      body: Center(
        child: Text('Count: ${(startValue ?? 0) + _count}'),
      ),
    );
  }
}
