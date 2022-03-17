import 'package:flutter/material.dart';

import 'src/concurrent_game_engine.dart';
import 'src/game_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameArea(),
    );
  }
}

class GameArea extends StatefulWidget {
  const GameArea({Key? key}) : super(key: key);

  @override
  State<GameArea> createState() => _GameAreaState();
}

class _GameAreaState extends State<GameArea> {
  GameEngine? _engine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Can you beat Dash in Tic Tac Toe?'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _engine = null;
              });
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Row(
        children: [
          const Expanded(child: Avatar(name: 'Michael')),
          Center(
            child: _engine == null
                ? SizedBox(
                    width: 150,
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            child: const Text('Sync Engine'),
                            onPressed: () async {
                              final GameEngine engine = GameEngine();
                              await engine.newGame();
                              setState(() {
                                _engine = engine;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            child: const Text('Isolate Engine'),
                            onPressed: () async {
                              final GameEngine engine = ConcurrentGameEngine();
                              await engine.newGame();
                              setState(() {
                                _engine = engine;
                              });
                            },
                          ),
                        ],
                      ),
                    ))
                : SquareField(engine: _engine!),
          ),
          const Expanded(child: Avatar(name: 'Dash')),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({Key? key, required this.name}) : super(key: key);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        Text(name),
      ],
    );
  }
}

class SquareField extends StatefulWidget {
  const SquareField({Key? key, required this.engine}) : super(key: key);

  final GameEngine engine;

  @override
  State<SquareField> createState() => _SquareFieldState();
}

class _SquareFieldState extends State<SquareField> {
  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_update);
  }

  @override
  void didUpdateWidget(SquareField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.removeListener(_update);
      widget.engine.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.engine.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {
      // state in the engine has changed.
    });
  }

  Widget? _markingForSquare(int col, int row) {
    switch (widget.engine.uiState.markingForSquare(col, row)) {
      case Player.dash:
        return const Text('D');
      case Player.human:
        return const Text('H');
      case null:
        return null;
    }
  }

  bool _squareActive(int col, int row) {
    return widget.engine.uiState.currentTurn == Player.human &&
        widget.engine.uiState.markingForSquare(col, row) == null;
  }

  String _winnerText(Player? winner) {
    switch (winner) {
      case Player.dash:
        return 'Game Over! Dash won!';
      case Player.human:
        return 'Congratulations! You won!';
      case null:
        return "It's a tie!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < 3; col++)
                InkWell(
                  onTap: _squareActive(row, col)
                      ? () {
                          widget.engine.mark(row, col);
                        }
                      : null,
                  child: Container(
                    height: 50,
                    width: 50,
                    color: Colors.grey,
                    child: Center(
                      child: _markingForSquare(row, col),
                    ),
                  ),
                )
            ],
          ),
        if (widget.engine.uiState.gameOver)
          Text(_winnerText(widget.engine.uiState.winner))
        else
          Text(
            widget.engine.uiState.currentTurn == Player.human
                ? 'Your turn!'
                : 'Dash is thinking...',
          ),
      ],
    );
  }
}
