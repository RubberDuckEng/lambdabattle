import 'package:flutter/material.dart';

const int kBoardWidth = 8;
const int kBoardHeight = 8;

class Position {
  final int x;
  final int y;

  Position(this.x, this.y);
}

class Player {
  // TODO: We should separate player from position and from piece.
  final Position position;
  final Color color;

  Player({required this.position, required this.color});

  Player move(Move move) {
    return Player(
      position: Position(position.x + move.dx, position.y + move.dy),
      color: color,
    );
  }
}

class GameState {
  final List<Player> players;
  final int currentPlayerIndex;

  int nextPlayerIndex() {
    return (currentPlayerIndex + 1) % players.length;
  }

  Player activePlayer() {
    return players[currentPlayerIndex];
  }

  GameState()
      : players = <Player>[
          Player(position: Position(0, 0), color: Colors.purple),
          Player(
              position: Position(kBoardWidth - 1, kBoardHeight - 1),
              color: Colors.amber)
        ],
        currentPlayerIndex = 0;

  GameState._(this.players, this.currentPlayerIndex);

  GameState afterMove(Move move) {
    var nextPlayers = List<Player>.from(players);
    nextPlayers[currentPlayerIndex] = activePlayer().move(move);
    return GameState._(nextPlayers, nextPlayerIndex());
  }
}

class Move {
  final int dx;
  final int dy;

  Move(this.dx, this.dy);
}

class AgentBoardView {
  final GameState _gameState;
  final Player _player;

  AgentBoardView(this._gameState, this._player);

  bool isValidPosition(Position position) {
    return position.x >= 0 &&
        position.x < kBoardWidth &&
        position.y >= 0 &&
        position.y < kBoardHeight;
  }

  bool isValidMove(Move move) {
    var player = _player.move(move);
    return isValidPosition(player.position);
  }

  Iterable<Move> get validMoves sync* {
    for (int dx = -1; dx <= 1; ++dx) {
      for (int dy = -1; dy <= 1; ++dy) {
        // TODO: Should be checked by isValidMove.
        if (dx == 0 && dy == 0) {
          continue;
        }
        var move = Move(dx, dy);
        if (isValidMove(move)) {
          yield move;
        }
      }
    }
  }
}

abstract class Agent {
  Move pickMove(AgentBoardView view);
}

class GameController {
  List<Agent> agents = <Agent>[FirstMover(), FirstMover()];

  Agent activeAgent(GameState gameState) {
    return agents[gameState.currentPlayerIndex];
  }

  GameState takeTurn(GameState gameState) {
    var agent = activeAgent(gameState);
    var view = AgentBoardView(gameState, gameState.activePlayer());
    var move = agent.pickMove(view);
    // TODO: Validate move?
    return gameState.afterMove(move);
  }
}
