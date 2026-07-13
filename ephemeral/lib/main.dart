import 'package:ephemeral/ephemeral.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ephemeral Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ephemeral Widget Demo'),
        ),
        body: const Ephemeral.asset(
          assetPath: 'assets/counter.js',
        ),
      ),
    );
  }
}
