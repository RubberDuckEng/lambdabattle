import 'dart:math';

import 'package:flutter/material.dart';

const int kMoveRange = 8;

class Delta {
  final int dx;
  final int dy;

  const Delta(this.dx, this.dy);

  @override
  String toString() => '<Δ$dx, Δ$dy>';

  double get magnitude => sqrt(dx * dx + dy * dy);
  int get walkingDistance => max(dx.abs(), dy.abs());

  @override
  bool operator ==(other) {
    if (other is! Delta) {
      return false;
    }
    return dx == other.dx && dy == other.dy;
  }

  @override
  int get hashCode {
    return hashValues(dx, dy);
  }
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  factory Position.random() {
    final rng = Random();
    return Position(rng.nextInt(Board.kWidth), rng.nextInt(Board.kHeight));
  }

  Position apply(Delta delta) => Position(x + delta.dx, y + delta.dy);
  Move move(Delta delta) => Move(this, apply(delta));

  Delta deltaTo(Position other) {
    return Delta(other.x - x, other.y - y);
  }

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(other) {
    if (other is! Position) {
      return false;
    }
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode {
    return hashValues(x, y);
  }
}

class Move {
  final Position initialPosition;
  final Position finalPosition;

  const Move(this.initialPosition, this.finalPosition);

  @override
  String toString() => '[$initialPosition -> $finalPosition]';

  @override
  bool operator ==(other) {
    if (other is! Move) {
      return false;
    }
    return initialPosition == other.initialPosition &&
        finalPosition == other.finalPosition;
  }

  Delta get delta => initialPosition.deltaTo(finalPosition);

  @override
  int get hashCode {
    return hashValues(initialPosition, finalPosition);
  }
}

abstract class Player {
  String get name;
  Color get color;

  const Player();

  void paint(Canvas canvas, Rect rect, PieceType type) {
    final Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.color = color;
    switch (type) {
      case PieceType.king:
        canvas.drawOval(rect, paint);
    }
  }

  @override
  String toString() => 'Player[$name]';
}

enum PieceType {
  king,
}

class Piece {
  final PieceType type;
  final Player owner;

  const Piece(this.type, this.owner);

  Iterable<Delta> get deltas sync* {
    switch (type) {
      case PieceType.king:
        for (int x = -1; x <= 1; ++x) {
          for (int y = -1; y <= 1; ++y) {
            for (int d = 1; d <= kMoveRange; ++d) {
              int dx = d * x;
              int dy = d * y;
              if (dx == 0 && dy == 0) {
                continue;
              }
              yield Delta(dx, dy);
            }
          }
        }
        break;
    }
  }
}

class IllegalMove {
  final String reason;
  const IllegalMove(this.reason);
}

class Board {
  static const int kWidth = 8;
  static const int kHeight = 8;

  static bool inBounds(Position position) {
    return position.x >= 0 &&
        position.x < kWidth &&
        position.y >= 0 &&
        position.y < kHeight;
  }

  final Map<Position, Piece> _pieces;

  Board.empty() : _pieces = <Position, Piece>{};
  Board._(this._pieces);

  void forEachPiece(void Function(Position position, Piece piece) callback) {
    _pieces.forEach(callback);
  }

  Board placeAt(Position position, Piece piece) {
    return Board._(<Position, Piece>{position: piece, ..._pieces});
  }

  Piece? getAt(Position position) {
    return _pieces[position];
  }

  Board move(Player player, Move move) {
    final piece = getAt(move.initialPosition);
    if (piece == null) {
      throw IllegalMove('No piece at ${move.initialPosition}.');
    }
    if (piece.owner != player) {
      throw IllegalMove(
          'Piece at ${move.initialPosition} not owned by $player.');
    }
    if (!inBounds(move.finalPosition)) {
      throw IllegalMove(
          'Final position ${move.finalPosition} is out-of-bounds.');
    }
    if (piece.owner == getAt(move.finalPosition)?.owner) {
      throw IllegalMove(
          'Pieces at ${move.initialPosition} and ${move.finalPosition} have the same owner.');
    }
    final newPieces = <Position, Piece>{..._pieces};
    newPieces.remove(move.initialPosition);
    newPieces[move.finalPosition] = piece;
    return Board._(newPieces);
  }

  bool isLegalMove(Player player, Move move) {
    final piece = getAt(move.initialPosition);
    return piece != null &&
        piece.owner == player &&
        _canMovePieceTo(piece, move.finalPosition);
  }

  bool _canMovePieceTo(Piece piece, Position position) {
    return inBounds(position) && piece.owner != getAt(position)?.owner;
  }

  Iterable<Move> getLegalMoves(Player player) sync* {
    for (final position in _pieces.keys) {
      final piece = getAt(position);
      if (piece == null || piece.owner != player) {
        continue;
      }
      for (final delta in piece.deltas) {
        final move = position.move(delta);
        if (_canMovePieceTo(piece, move.finalPosition)) {
          assert(isLegalMove(player, move));
          yield move;
        }
      }
    }
  }

  bool hasPieceOfType(Player player, PieceType type) {
    for (final piece in _pieces.values) {
      if (piece.owner == player && piece.type == type) {
        return true;
      }
    }
    return false;
  }

  bool isAlive(Player player) => hasPieceOfType(player, PieceType.king);
}

class GameState {
  final Board board;
  // In move order.
  final List<Player> players;
  // In death order.
  final List<Player> deadPlayers;
  static const int turnsUntilDrawDefault = 50;
  final int turnsUntilDraw;

  Player get activePlayer => players.first;

  GameState(this.board, this.players, this.deadPlayers,
      [this.turnsUntilDraw = turnsUntilDrawDefault]);

  GameState.empty() : this(Board.empty(), const <Player>[], const <Player>[]);

  GameState move(Move move) {
    final newBoard = board.move(activePlayer, move);
    final newPlayers = <Player>[];
    final newDeadPlayers = List<Player>.from(deadPlayers);
    for (int i = 1; i < players.length; ++i) {
      final player = players[i];
      if (newBoard.isAlive(player)) {
        newPlayers.add(player);
      } else {
        newDeadPlayers.add(player);
      }
    }
    newPlayers.add(activePlayer);
    int newTurnsUntilDraw = turnsUntilDraw - 1;
    final bool playerDied = players.length != newPlayers.length;
    if (playerDied) {
      newTurnsUntilDraw = turnsUntilDrawDefault;
    }
    return GameState(newBoard, newPlayers, newDeadPlayers, newTurnsUntilDraw);
  }

  bool get isDraw => turnsUntilDraw <= 0;

  Player? get winner {
    if (players.length != 1) {
      return null;
    }
    return activePlayer;
  }

  bool get isDone => isDraw || winner != null;
}

class AgentView {
  final GameState _gameState;
  final Player _player;

  AgentView(this._gameState, this._player);

  List<Position> _getPositionsIf(bool Function(Piece piece) predicate) {
    List<Position> positions = <Position>[];
    _gameState.board.forEachPiece((position, piece) {
      if (predicate(piece)) {
        positions.add(position);
      }
    });
    return positions;
  }

  List<Position> getPositions(PieceType type) {
    return _getPositionsIf(
      (piece) => piece.owner == _player && piece.type == type,
    );
  }

  List<Position> enemyPositions(PieceType type) {
    return _getPositionsIf(
      (piece) => piece.owner != _player && piece.type == type,
    );
  }

  Position? closestOpponent(Position position, PieceType type) {
    Position? bestPosition;
    double bestDistance = double.infinity;
    _gameState.board.forEachPiece((currentPosition, piece) {
      if (piece.owner == _player || piece.type != type) {
        return;
      }
      final double currentDistance =
          position.deltaTo(currentPosition).magnitude;
      if (currentDistance < bestDistance) {
        bestDistance = currentDistance;
        bestPosition = currentPosition;
      }
    });
    return bestPosition;
  }

  Iterable<Move> get legalMoves => _gameState.board.getLegalMoves(_player);
}

const double kValue = 16.0;
const double initialRating = 500.0;

class GameHistory {
  final Map<String, double> wins = <String, double>{};
  final Map<String, double> rating = <String, double>{};
  final Map<String, Color> colors = <String, Color>{};
  final Map<String, double> lastGameRating = <String, double>{};

  Player? lastWinner;
  int gameCount = 0;
  List<String> deadPlayers = [];

  double expectedScore(double currentRating, double opponentRating) {
    final double exponent = (opponentRating - currentRating) / 400.0;
    return 1.0 / (1.0 + pow(10.0, exponent));
  }

  double pointsToTransfer(double score, double expectedScore) {
    return kValue * (score - expectedScore);
  }

  double currentRatingForName(String name) {
    return rating[name] ?? initialRating;
  }

  double currentRating(Player player) => currentRatingForName(player.name);

  void adjustRating(Player player, double delta) {
    lastGameRating[player.name] = currentRating(player);
    rating[player.name] = currentRating(player) + delta;
  }

  void updateRating(Player winner, Player loser, double score) {
    final winnerRating = currentRating(winner);
    final loserRating = currentRating(loser);
    final stake =
        pointsToTransfer(score, expectedScore(winnerRating, loserRating));
    adjustRating(winner, stake);
    adjustRating(loser, -stake);
  }

  void recordRatings(List<Player> alivePlayers, List<Player> deadPlayers) {
    // http://www.tckerrigan.com/Misc/Multiplayer_Elo/
    // record dead players as losing against the next dead.
    for (int i = 0; i < deadPlayers.length - 1; i++) {
      final winner = deadPlayers[i + 1];
      final loser = deadPlayers[i];
      updateRating(winner, loser, 1.0); // win
    }
    alivePlayers.shuffle();
    // record last dead player as losing against random alive player?
    if (deadPlayers.isNotEmpty) {
      updateRating(alivePlayers.first, deadPlayers.last, 1.0); // win
    }
    // record alive players in a cycle of draws.
    for (int i = 0; i < alivePlayers.length; i++) {
      for (int j = i + 1; j < alivePlayers.length; j++) {
        updateRating(alivePlayers[i], alivePlayers[j], 0.5); // draw
      }
    }
  }

  void recordGame(GameState gameState) {
    final pointsPerPlayer = 1.0 / gameState.players.length;
    for (final player in gameState.players) {
      final name = player.name;
      wins[name] = (wins[name] ?? 0.0) + pointsPerPlayer;
      colors[name] = player.color;
      gameCount += 1;
    }

    final haveSeen = <Type, bool>{};

    bool checkPlayer(p) {
      final didSeeBefore = haveSeen[p.runtimeType] ?? false;
      haveSeen[p.runtimeType] = true;
      return !didSeeBefore;
    }

    final alivePlayers = gameState.players.where(checkPlayer).toList();
    final deadPlayers = gameState.deadPlayers.where(checkPlayer).toList();
    recordDeadPlayer(deadPlayers);
    recordWinner(gameState.winner);
    recordRatings(alivePlayers, deadPlayers);
  }

  void recordWinner(Player? player) {
    lastWinner = player;
  }

  bool isWinner(String name) {
    return lastWinner?.name == name;
  }

  void recordDeadPlayer(List<Player> _deadPlayers) {
    deadPlayers = _deadPlayers.map((p) => p.name).toList();
  }

  bool playerIsDead(String name) {
    return deadPlayers.contains(name);
  }

  RatingState ratingState(String name) {
    if (gameCount == 0) return RatingState.none;
    final lastRating = lastGameRating[name];
    final currentRating = rating[name];

    if (currentRating != null && lastRating != null) {
      if (currentRating == lastRating) return RatingState.none;
      if (currentRating < lastRating) return RatingState.dropped;
      if (currentRating > lastRating) return RatingState.increased;
    }
    return RatingState.none;
  }
}

enum RatingState {
  none,
  dropped,
  increased,
}

abstract class Agent extends Player {
  const Agent();

  Move pickMove(AgentView view);
}
