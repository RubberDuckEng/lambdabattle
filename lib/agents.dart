import 'dart:math';
import 'engine.dart';

import 'package:flutter/material.dart';

typedef AgentFactory = Agent Function();

List<AgentFactory> all = <AgentFactory>[
  () => FirstMover(),
  () => RandomMover(),
  () => Fixate(),
  () => Seeker(),
  () => CautiousSeeker(),
  () => Runner(),
  () => Opportunist(),
];

class FirstMover extends Agent {
  @override
  String get name => "FirstMover";

  @override
  Color get color => Colors.teal;

  @override
  Move pickMove(AgentView view) {
    return view.legalMoves.first;
  }
}

Move _findRandomMove(Iterable<Move> legalMoves) {
  var rng = Random();
  var choices = legalMoves.toList();
  return choices[rng.nextInt(choices.length)];
}

class RandomMover extends Agent {
  @override
  String get name => "RandomMover";

  @override
  Color get color => Colors.purple;

  @override
  Move pickMove(AgentView view) {
    return _findRandomMove(view.legalMoves);
  }
}

class Fixate extends Agent {
  Delta? favorite;

  Move? getMatchingFavorite(List<Move> legalMoves) {
    var favorite = this.favorite;
    if (favorite != null) {
      for (var move in legalMoves) {
        if (move.delta == favorite) {
          return move;
        }
      }
    }
    return null;
  }

  @override
  String get name => "Fixate";

  @override
  Color get color => Colors.brown;

  @override
  void paint(Canvas canvas, Rect rect, PieceType type) {
    super.paint(canvas, rect, type);
    var favorite = this.favorite;
    if (favorite != null) {
      var paint = Paint();
      paint.color = Colors.brown.shade900;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 4.0;
      var center = rect.center;
      var offset = Offset(1.0 * favorite.dx, 1.0 * favorite.dy);
      offset /= offset.distance;
      var target = center +
          Offset(offset.dx * rect.width / 2.0, offset.dy * rect.height / 2.0);
      var path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(target.dx, target.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  Move pickMove(AgentView view) {
    var legalMoves = view.legalMoves.toList();
    var move = getMatchingFavorite(legalMoves) ?? _findRandomMove(legalMoves);
    favorite = move.delta;
    return move;
  }
}

Move _findMoveByDistanceToTarget(AgentView view, Position targetPosition,
    bool Function(double currentDistance, double bestDistance) isBetter) {
  Move? bestMove;
  double? bestDistance;
  for (var move in view.legalMoves) {
    var currentDistance = move.finalPosition.deltaTo(targetPosition).magnitude;
    if (bestDistance == null || isBetter(currentDistance, bestDistance)) {
      bestDistance = currentDistance;
      bestMove = move;
    }
  }
  return bestMove!;
}

class Seeker extends Agent {
  Delta? target;

  @override
  String get name => "Seeker";

  @override
  Color get color => Colors.blue;

  @override
  void paint(Canvas canvas, Rect rect, PieceType type) {
    super.paint(canvas, rect, type);
    var target = this.target;
    if (target != null) {
      var paint = Paint();
      paint.color = color;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 4.0;
      var offset = Offset(target.dx * rect.width, target.dy * rect.height);
      var reticle = rect.translate(offset.dx, offset.dy);
      canvas.drawOval(reticle.inflate(3.0), paint);
    }
  }

  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      target = null;
      return _findRandomMove(view.legalMoves);
    }
    var move = _findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance < bestDistance;
    });
    target = move.finalPosition.deltaTo(targetPosition);
    return move;
  }
}

/// Tries to get as close to other pieces, but not too close.
class CautiousSeeker extends Agent {
  @override
  String get name => "CautiousSeeker";
  @override
  Color get color => Colors.orange;

  int _distanceToNearestPiece(Move move, List<Position> pieces) {
    assert(pieces.isNotEmpty);
    return pieces
        .map((e) => e.deltaTo(move.finalPosition).walkingDistance)
        .fold(
            null,
            (int? previousValue, element) =>
                (previousValue == null || element < previousValue)
                    ? element
                    : previousValue)!;
  }

  @override
  Move pickMove(AgentView view) {
    final otherKings = view.enemyPositions(PieceType.king);
    // If at the end of the move we would be next to another piece (distance == 1)
    // it is not safe! We could be eaten in the next round.
    // We still allow distances of 0, in which case we eat the enemy piece.
    final safeMoves = view.legalMoves
        .where(
          (move) => !otherKings
              .map((e) => e.deltaTo(move.finalPosition).walkingDistance)
              .contains(1),
        )
        .toList();
    if (safeMoves.isEmpty) {
      // If there are no safe moves, choose a random move.
      // There may be a better heuristic to find the "safest" move in this case.
      return _findRandomMove(view.legalMoves);
    }
    // Find the move that brings us closest to an opponent.
    Move? bestMove;
    int? bestDistance;
    for (final move in safeMoves) {
      final distance = _distanceToNearestPiece(move, otherKings);
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestMove = move;
      }
    }
    return bestMove!;
  }
}

class Runner extends Agent {
  @override
  String get name => "Runner";

  @override
  Color get color => Colors.pink;

  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      return _findRandomMove(view.legalMoves);
    }
    return _findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance > bestDistance;
    });
  }
}

class Opportunist extends Agent {
  @override
  String get name => "Opportunist";

  @override
  Color get color => Colors.green;

  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      return _findRandomMove(view.legalMoves);
    }
    for (var move in view.legalMoves) {
      if (move.finalPosition == targetPosition) {
        return move;
      }
    }
    return _findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance > bestDistance;
    });
  }
}
