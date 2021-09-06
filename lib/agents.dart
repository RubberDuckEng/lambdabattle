import 'engine.dart';

class FirstMover implements Agent {
  @override
  Move pickMove(AgentView view) {
    return view.legalMoves.first;
  }
}
