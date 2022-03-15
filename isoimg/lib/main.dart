import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image/image.dart' as image;
import 'package:loading_indicator/loading_indicator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Processing Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = false;

  Uint8List? _image;
  Uint8List? _originalImage;

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/tulips.jpg').then((ByteData data) {
      setState(() {
        _originalImage = data.buffer.asUint8List();
        _image = _originalImage;
      });
    });
  }

  static Uint8List _applySepiaFilter(Uint8List original) {
    final image.Image decoded = image.decodeImage(original.toList())!;
    final image.Image sepia = image.sepia(decoded);
    final Uint8List encoded = Uint8List.fromList(image.encodeJpg(sepia));
    return encoded;
  }

  void _applySepiaFilterSync() {
    setState(() {
      _loading = true;
    });
    final Uint8List filtered = _applySepiaFilter(_image!);
    setState(() {
      _image = filtered;
      _loading = false;
    });
  }

  void _applySepiaFilterAsync() {
    setState(() {
      _loading = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      final Uint8List filtered = _applySepiaFilter(_image!);
      setState(() {
        _image = filtered;
        _loading = false;
      });
    });
  }

  Future<void> _applySepiaFilterInIsolate() async {
    setState(() {
      _loading = true;
    });
    final Uint8List encoded = await compute(_applySepiaFilter, _image!);
    // Alternative with Isolate.run (currently crashes).
    // final Uint8List encoded = await Isolate.run(() => _applySepiaFilter(_image!));
    setState(() {
      _image = encoded;
      _loading = false;
    });
  }

  void _reset() {
    setState(() {
      _image = _originalImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Processing Demo'),
      ),
      body: Stack(
        children: [
          if (_image != null)
            Center(
              child: Image.memory(
                _image!,
                gaplessPlayback: true,
              ),
            ),
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _loading ? 1.0 : 0.0,
              child: Container(
                color: Colors.white.withOpacity(.8),
                child: const Center(
                  child: LoadingIndicator(
                    indicatorType: Indicator.ballGridPulse,
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      persistentFooterButtons: <Widget>[
        TextButton(
          onPressed: _image == _originalImage && !_loading
              ? _applySepiaFilterSync
              : null,
          child: const Text('Sepia (sync)'),
        ),
        TextButton(
          onPressed: _image == _originalImage && !_loading
              ? _applySepiaFilterAsync
              : null,
          child: const Text('Sepia (async)'),
        ),
        TextButton(
          onPressed: _image == _originalImage && !_loading
              ? _applySepiaFilterInIsolate
              : null,
          child: const Text('Sepia (isolate)'),
        ),
        TextButton(
          onPressed: _image != _originalImage && !_loading ? _reset : null,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
