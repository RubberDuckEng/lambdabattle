import 'dart:math';
import 'engine.dart';

class FirstMover extends Agent {
  @override
  Move pickMove(AgentView view) {
    return view.legalMoves.first;
  }
}

class RandomMover extends Agent {
  @override
  Move pickMove(AgentView view) {
    var rng = Random();
    var choices = view.legalMoves.toList();
    return choices[rng.nextInt(choices.length)];
  }
}

abstract class DistanceEvaluatorAgent extends Agent {
  bool isBetter(double currentDistance, double bestDistance);

  @override
  Move pickMove(AgentView view) {
    var myKing = view.getPositions(PieceType.king).first;
    var targetPosition = view.closestOpponent(myKing, PieceType.king);
    if (targetPosition == null) {
      return view.legalMoves.first;
    }
    Move? bestMove;
    double? bestDistance;
    for (var move in view.legalMoves) {
      var currentDistance =
          move.finalPosition.deltaTo(targetPosition).magnitude;
      if (bestDistance == null || isBetter(currentDistance, bestDistance)) {
        bestDistance = currentDistance;
        bestMove = move;
      }
    }
    return bestMove!;
  }
}

class Seeker extends DistanceEvaluatorAgent {
  @override
  bool isBetter(double currentDistance, double bestDistance) {
    return currentDistance < bestDistance;
  }
}

class Runner extends DistanceEvaluatorAgent {
  @override
  bool isBetter(double currentDistance, double bestDistance) {
    return currentDistance > bestDistance;
  }
}
