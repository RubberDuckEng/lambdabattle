import 'dart:math';
import 'engine.dart';

class FirstMover extends Agent {
  @override
  Move pickMove(AgentView view) {
    return view.legalMoves.first;
  }
}

Move findRandomMove(Iterable<Move> legalMoves) {
  var rng = Random();
  var choices = legalMoves.toList();
  return choices[rng.nextInt(choices.length)];
}

class RandomMover extends Agent {
  @override
  Move pickMove(AgentView view) {
    return findRandomMove(view.legalMoves);
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
  Move pickMove(AgentView view) {
    var legalMoves = view.legalMoves.toList();
    var move = getMatchingFavorite(legalMoves) ?? findRandomMove(legalMoves);
    favorite = move.delta;
    return move;
  }
}

Move findMoveByDistanceToTarget(AgentView view, Position targetPosition,
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
  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      return findRandomMove(view.legalMoves);
    }
    return findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance < bestDistance;
    });
  }
}

class Runner extends Agent {
  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      return findRandomMove(view.legalMoves);
    }
    return findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance > bestDistance;
    });
  }
}

class Opportunist extends Agent {
  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      return findRandomMove(view.legalMoves);
    }
    for (var move in view.legalMoves) {
      if (move.finalPosition == targetPosition) {
        return move;
      }
    }
    return findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance > bestDistance;
    });
  }
}
