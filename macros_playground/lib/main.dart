import 'package:flutter/material.dart';

import 'src/macro.dart';

void main() {
  runApp(const Foo());
}

@Stateful()
class Foo extends State { // TODO: The macro could add "extends State implements Widget", https://github.com/dart-lang/sdk/issues/55425
  @input String? get name;
  @input int? get age;

  int _count = 0;

  @override
  Widget build(BuildContext context) {
    key
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
        child: Text('Count: $_count'),
      ),
    );
  }
}
