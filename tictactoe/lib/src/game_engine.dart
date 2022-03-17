import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

class GameEngine extends ChangeNotifier {
  UiState get uiState => _uiState;
  UiState _uiState = UiState._start();

  Future<void> newGame() async {
    _uiState = UiState._start();
    notifyListeners();
  }

  Future<void> mark(int row, int col) async {
    _uiState = _calculateNewState(_toSquareIndex(row, col), Player.human);
    notifyListeners();
    // Yield, to give listeners some time to update UI based on new State.
    await Future.delayed(const Duration(milliseconds: 250));
    if (!uiState.gameOver) {
      _calculateDashMove();
    }
  }

  UiState _calculateNewState(int squareIndex, Player player) {
    assert(uiState.currentTurn == player);
    assert(!_uiState.gameOver);
    assert(uiState._squares[squareIndex] == null);

    final List<Player?> squares = [...uiState._squares]
      ..[squareIndex] = player;
    final bool didWin = _didWin(player, squares);
    final bool gameOver =
        didWin || squares.every((Player? player) => player != null);

    return UiState._(
      squares: squares,
      winner: didWin ? player : null,
      gameOver: gameOver,
      currentTurn: gameOver
          ? null
          : (player == Player.dash ? Player.human : Player.dash),
    );
  }

  // TODO: Implement something smarter than random.
  final Random _random = Random();

  void _calculateDashMove() {
    assert(!uiState.gameOver);
    int nextMove;
    do {
      nextMove = _random.nextInt(9);
      sleep(const Duration(seconds: 2)); // Dash is a slow thinker and hogs the CPU while thinking.
    } while (uiState._squares[nextMove] != null);
    _uiState = _calculateNewState(nextMove, Player.dash);
    notifyListeners();
  }

  bool _didWin(Player player, List<Player?> squares) {
    return (squares[0] == player &&
            squares[1] == player &&
            squares[2] == player) ||
        (squares[3] == player &&
            squares[4] == player &&
            squares[5] == player) ||
        (squares[6] == player &&
            squares[7] == player &&
            squares[8] == player) ||
        (squares[0] == player &&
            squares[4] == player &&
            squares[8] == player) ||
        (squares[2] == player &&
            squares[4] == player &&
            squares[6] == player) ||
        (squares[0] == player &&
            squares[3] == player &&
            squares[6] == player) ||
        (squares[1] == player &&
            squares[4] == player &&
            squares[7] == player) ||
        (squares[2] == player && squares[5] == player && squares[8] == player);
  }
}

class UiState {
  UiState._({
    required List<Player?> squares,
    required this.winner,
    required this.gameOver,
    required this.currentTurn,
  }) : _squares = squares;

  factory UiState._start() {
    return UiState._(
      squares: List.filled(9, null),
      winner: null,
      gameOver: false,
      currentTurn: Player.human,
    );
  }

  final List<Player?> _squares;
  final Player? winner;
  final bool gameOver;
  final Player? currentTurn;

  Player? markingForSquare(int row, int col) {
    return _squares[_toSquareIndex(row, col)];
  }
}

enum Player {
  dash,
  human,
}

int _toSquareIndex(int row, int col) {
  return col + row * 3;
}
