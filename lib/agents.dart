import 'dart:math';
import 'engine.dart';

import 'package:flutter/material.dart';

typedef AgentFactory = Agent Function();

List<AgentFactory> all = <AgentFactory>[
  () => FirstMover(),
  () => RandomMover(),
  () => Fixate(),
  () => Seeker(),
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
  Color get color => Colors.lime;

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
  @override
  String get name => "Seeker";

  @override
  Color get color => Colors.blue;

  @override
  Move pickMove(AgentView view) {
    var initialPosition = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(initialPosition, PieceType.king);
    if (targetPosition == null) {
      return _findRandomMove(view.legalMoves);
    }
    return _findMoveByDistanceToTarget(view, targetPosition,
        (double currentDistance, double bestDistance) {
      return currentDistance < bestDistance;
    });
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
