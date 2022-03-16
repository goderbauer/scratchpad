import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;

import 'progress_widget.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  bool _loading = false;
  Uint8List? _image;

  void _loadImage(String? path) {
    if (path == null) return;

    setState(() {
      _loading = true;
    });
    final image = File(path).readAsBytesSync();
    setState(() {
      _image = image;
      _loading = false;
    });
  }

  static Uint8List _applySepiaFilter(Uint8List original) {
    final decoded = image.decodeImage(original.toList())!;
    final sepia = image.sepia(decoded);
    final encoded = Uint8List.fromList(image.encodeJpg(sepia));
    return encoded;
  }

  void _applySepia() {
    setState(() {
      _loading = true;
    });
    final image = _applySepiaFilter(_image!);
    setState(() {
      _image = image;
      _loading = false;
    });
  }

  void _showImagePicker({@required sync}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    _loadImage(result?.files.single.path);
  }

  void _clear() {
    setState(() {
      _image = null;
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
              child: Image.memory(_image!, gaplessPlayback: true),
            ),
          ProgressWidget(loading: _loading),
          if (_image == null && !_loading)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showImagePicker(sync: true);
                    },
                    child: const Text('Load'),
                  ),
                ],
              ),
            ),
        ],
      ),
      persistentFooterButtons: <Widget>[
        TextButton(
          onPressed: !_loading && _image != null ? _applySepia : null,
          child: const Text('Sepia (sync)'),
        ),
        TextButton(
          onPressed: _image != null ? _clear : null,
          child: const Text('Clear'),
        ),
      ],
    );
  }
}
