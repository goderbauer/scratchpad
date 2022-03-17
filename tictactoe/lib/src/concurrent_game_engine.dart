import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';

import 'game_engine.dart';

class ConcurrentGameEngine implements GameEngine {
  final ReceivePort _receivePort = ReceivePort();
  late final StreamQueue<Object?> _receiveQueue = StreamQueue<Object?>(
    _receivePort,
  );
  SendPort? _sendPort;
  Isolate? _isolate;

  @override
  Future<UiState> start() async {
    if (_isolate == null) {
      _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort.sendPort);
      _sendPort = await _receiveQueue.next as SendPort;
    }
    _sendPort!.send('start');
    return (await _receiveQueue.next) as UiState;
  }

  @override
  Future<UiState> reportMove(int row, int col) async {
    _sendPort!.send([row, col]);
    return (await _receiveQueue.next) as UiState;
  }

  @override
  Future<UiState> makeMove() async {
    _sendPort!.send('makeMove');
    return (await _receiveQueue.next) as UiState;
  }

  @override
  void dispose() {
    _receiveQueue.cancel();
    _receivePort.close();
    _isolate?.kill();
    _isolate = null;
  }
}

void _isolateEntryPoint(SendPort sendPort) {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final GameEngine engine = GameEngine();

  receivePort.listen((Object? message) async {
    final UiState uiState;
    if (message == 'start') {
      uiState = await engine.start();
    } else if (message == 'makeMove') {
      uiState = await engine.makeMove();
    } else if (message is List<int> && message.length == 2) {
      uiState = await engine.reportMove(message.first, message.last);
    } else {
      throw Exception('Invalid message sent to isolate: $message');
    }
    sendPort.send(uiState);
  });
}
