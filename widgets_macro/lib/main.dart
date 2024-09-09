import 'package:flutter/material.dart';

import 'src/macro.dart';

void main() {
  runApp(const App(name: 'Dash'));
}

@Stateless()
class App {
  const App({
    super.key,
    required String name,
  });

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

@Stateful('_CounterState') // TODO: pass in as type and not string.
class Counter {
  const Counter({
    super.key,
    required String name,
    int startValue = 0,
  }) : assert(startValue > 0);
}

class _CounterState extends State<Counter> { // TODO: can we avoid the "extends State"? Answer: Currently no.
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hello ${widget.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _count += 1;
          });
        },
      ),
      body: Center(
        child: Text('Count: ${widget.startValue + _count}'),
      ),
    );
  }
}
