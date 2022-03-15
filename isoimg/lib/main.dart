import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
      debugShowCheckedModeBanner: false,
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

  void _loadImageSync(String path) {
    setState(() {
      _loading = true;
    });
    Uint8List data = File(path).readAsBytesSync();
    setState(() {
      // For the demo, remove the "reset" functionality and just set _image here.
      _originalImage = data;
      _image = _originalImage;
      _loading = false;
    });
  }

  Future<void> _loadImageAsync(String path) async {
    setState(() {
      _loading = true;
    });
    Uint8List data = await File(path).readAsBytes();
    setState(() {
      // For the demo, remove the "reset" functionality and just set _image here.
      _originalImage = data;
      _image = _originalImage;
      _loading = false;
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
    setState(() {
      _image = encoded;
      _loading = false;
    });
  }

  void _showImagePicker({@required sync}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      return;
    }
    if (sync) {
      _loadImageSync(result.files.single.path!);
    } else {
      _loadImageAsync(result.files.single.path!);
    }
  }

  void _reset() {
    setState(() {
      _image = _originalImage;
    });
  }

  void _clear() {
    setState(() {
      _image = null;
      _originalImage = null;
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
            )),
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
          if (_image == null && !_loading)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showImagePicker(sync: true);
                    },
                    child: const Text('Load (sync)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showImagePicker(sync: false);
                    },
                    child: const Text('Load (async)'),
                  ),
                ],
              ),
            ),
        ],
      ),
      persistentFooterButtons: <Widget>[
        TextButton(
          onPressed: _image == _originalImage && !_loading && _image != null
              ? _applySepiaFilterSync
              : null,
          child: const Text('Sepia (sync)'),
        ),
        TextButton(
          onPressed: _image == _originalImage && !_loading && _image != null
              ? _applySepiaFilterAsync
              : null,
          child: const Text('Sepia (async)'),
        ),
        TextButton(
          onPressed: _image == _originalImage && !_loading && _image != null
              ? _applySepiaFilterInIsolate
              : null,
          child: const Text('Sepia (isolate)'),
        ),
        TextButton(
          onPressed: _image != _originalImage && !_loading && _image != null
              ? _reset
              : null,
          child: const Text('Reset to Original'),
        ),
        TextButton(
          onPressed: _image != null
              ? _clear
              : null,
          child: const Text('Clear'),
        ),
      ],
    );
  }
}
