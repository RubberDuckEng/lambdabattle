// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import 'engine.dart';
import 'agents.dart' as agents;
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lambda Battle!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Lambda Battle!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GameState? gameState;
  GameController gameController = GameController.demo();
  final history = GameHistory();

  Timer? timer;

  @override
  void initState() {
    super.initState();
    gameState = gameController.getRandomInitialGameState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _handleTimer(Timer _) {
    nextTurn();

    var gameState = this.gameState;
    if (gameState == null) {
      return;
    }
    if (gameState.isDone) {
      history.recordGame(gameState);
      timer?.cancel();
      timer = null;
      _startBattle();
    }
  }

  void _startBattle() {
    gameState = gameController.getRandomInitialGameState();
    timer = Timer.periodic(const Duration(milliseconds: 1), _handleTimer);
  }

  void _stopBattle() {
    setState(() {
      timer?.cancel();
      timer = null;
    });
  }

  void nextTurn() {
    setState(() {
      gameState = gameController.takeTurn(gameState!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: BoardView(
              gameState: gameState!,
            ),
          ),
          Flexible(
            child: Center(
              child: LeaderBoard(history: history),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: timer == null ? _startBattle : _stopBattle,
        child: timer == null
            ? const Icon(Icons.play_arrow)
            : const Icon(Icons.stop),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class BoardView extends StatelessWidget {
  const BoardView({Key? key, required this.gameState}) : super(key: key);

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    var winner = gameState.winner;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: BoardPainter(gameState)),
        if (winner != null)
          Container(
              color: Colors.white.withOpacity(0.6),
              child: Center(child: Text('A winner is ${winner.name}'))),
      ],
    );
  }
}

class BoardPainter extends CustomPainter {
  final GameState gameState;

  BoardPainter(this.gameState);

  void paintBackground(Canvas canvas, Size size, Size cell) {
    var paint = Paint();
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < Board.kWidth; ++i) {
      for (int j = 0; j < Board.kHeight; ++j) {
        paint.color = ((i + j) % 2 == 0) ? Colors.black12 : Colors.black26;
        canvas.drawRect(rectForPosition(Position(i, j), cell), paint);
      }
    }
  }

  Rect rectForPosition(Position position, Size cell) {
    return Rect.fromLTWH(position.x * cell.width, position.y * cell.height,
        cell.width, cell.height);
  }

  void paintPieces(Canvas canvas, Size size, Size cell) {
    var paint = Paint();
    paint.style = PaintingStyle.fill;
    gameState.board.forEachPiece((position, piece) {
      paint.color = piece.owner.color;
      switch (piece.type) {
        case PieceType.king:
          canvas.drawOval(rectForPosition(position, cell), paint);
          break;
      }
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    var cellSize = Size(size.width / Board.kWidth, size.height / Board.kHeight);
    paintBackground(canvas, size, cellSize);
    paintPieces(canvas, size, cellSize);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class GameController {
  final Map<Player, Agent> _agents = <Player, Agent>{};

  GameController();

  factory GameController.demo() {
    var controller = GameController();

    controller.addPlayerWithAgent(
        const Player("Opportunist", Colors.green), agents.Opportunist());
    // controller.addPlayerWithAgent(
    //     const Player("Random", Colors.purple), agents.RandomMover());
    controller.addPlayerWithAgent(
        const Player("Seeker", Colors.blue), agents.Seeker());
    controller.addPlayerWithAgent(
        const Player("Runner1", Colors.pink), agents.Runner());
    controller.addPlayerWithAgent(
        const Player("Runner2", Colors.pink), agents.Runner());
    controller.addPlayerWithAgent(
        const Player("Runner3", Colors.pink), agents.Runner());
    controller.addPlayerWithAgent(
        const Player("Runner4", Colors.pink), agents.Runner());
    // controller.addPlayerWithAgent(
    //     const Player("Runner5", Colors.pink), agents.Runner());
    // controller.addPlayerWithAgent(
    //     const Player("Runner6", Colors.pink), agents.Runner());
    // controller.addPlayerWithAgent(
    //     const Player("FirstMover", Colors.teal), agents.FirstMover());
    // controller.addPlayerWithAgent(
    //     const Player("Fixate", Colors.lime), agents.Fixate());
    return controller;
  }

  void addPlayerWithAgent(Player player, Agent agent) {
    _agents[player] = agent;
  }

  GameState getRandomInitialGameState() {
    var board = Board.empty();
    var players = _agents.keys.toList();
    for (var player in players) {
      Position position;
      do {
        position = Position.random();
      } while (board.getAt(position) != null);

      board = board.placeAt(position, Piece(PieceType.king, player));
    }
    return GameState(board, players);
  }

  GameState takeTurn(GameState gameState) {
    var activePlayer = gameState.activePlayer;
    var view = AgentView(gameState, activePlayer);
    var activeAgent = _agents[activePlayer]!;
    return gameState.move(activeAgent.pickMove(view));
  }
}

class LeaderBoard extends StatelessWidget {
  final GameHistory history;

  const LeaderBoard({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String asPercent(double value) {
      var percent = (value / history.gameCount) * 100;
      return "${percent.toStringAsFixed(1)}%";
    }

    var entries = history.wins.entries.toList();
    entries.sort((lhs, rhs) => rhs.value.compareTo(lhs.value));

    return SizedBox(
        width: 200,
        child: Table(
          border: const TableBorder(
              top: BorderSide(color: Colors.black26),
              bottom: BorderSide(color: Colors.black26),
              right: BorderSide(color: Colors.black26),
              left: BorderSide(color: Colors.black26),
              verticalInside: BorderSide(color: Colors.black26)),
          children: <TableRow>[
                const TableRow(
                  decoration: const BoxDecoration(
                      color: Colors.black12,
                      border:
                          Border(bottom: BorderSide(color: Colors.black26))),
                  children: <Widget>[
                    const TableCell(
                      child: const Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: const Text("Player"),
                      ),
                    ),
                    const TableCell(
                      child: const Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: const Text("Score"),
                      ),
                    ),
                  ],
                ),
              ] +
              entries
                  .map(
                    (e) => TableRow(
                      children: <Widget>[
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(e.key),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(asPercent(e.value)),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
        ));
  }
}

// Goals:
// Draw a board
// GameState object
// Take turns / query the agent for a move.
// Write an "agent" / "piece"
