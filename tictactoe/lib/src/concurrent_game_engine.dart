import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'game_engine.dart';

class ConcurrentGameEngine  extends ChangeNotifier implements GameEngine {
  @override
  Future<void> mark(int row, int col) async {
    (await _sendPort.future).send([row, col]);
  }

  ReceivePort? _receivePort;
  final Completer<SendPort> _sendPort = Completer<SendPort>();

  @override
  Future<void> newGame() async {
    if (_receivePort == null) {
      _receivePort = ReceivePort()..listen((Object? message) {
        if (message is SendPort) {
          _sendPort.complete(message);
        } else if (message is UiState) {
          _uiState = message;
          notifyListeners();
        } else {
          throw Exception('Invalid message from isolate: $message');
        }
      });
      Isolate.spawn(_isolate, _receivePort!.sendPort);
    }
    (await _sendPort.future).send('new');
  }

  @override
  UiState get uiState => _uiState!;
  UiState? _uiState;
}

void _isolate(SendPort sendPort) {
  final GameEngine engine = GameEngine();

  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  engine.addListener(() {
    sendPort.send(engine.uiState);
  });

  receivePort.listen((Object? message) {
    if (message == 'new') {
      engine.newGame();
    } else if (message is List<int> && message.length == 2) {
      engine.mark(message.first, message.last);
    } else {
      throw Exception('Invalid message in isolate: $message');
    }
  });
}
