import 'dart:math';
import 'engine.dart';

class FirstMover implements Agent {
  @override
  Move pickMove(AgentView view) {
    return view.legalMoves.first;
  }
}

class RandomMover implements Agent {
  @override
  Move pickMove(AgentView view) {
    var rng = Random();
    var choices = view.legalMoves.toList();
    return choices[rng.nextInt(choices.length)];
  }
}
