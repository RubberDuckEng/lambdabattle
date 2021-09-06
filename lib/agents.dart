import 'engine.dart';

class FirstMover implements Agent {
  @override
  Move pickMove(AgentBoardView view) {
    return view.validMoves.first;
  }
}
