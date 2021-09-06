import 'package:flutter/material.dart';
import 'engine.dart';
import 'agents.dart' as agents;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  GameController gameController = GameController.random(2);

  @override
  void initState() {
    super.initState();
    gameState = gameController.getRandomInitialGameState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: BoardView(
            gameState: gameState!,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            gameState = gameController.takeTurn(gameState!);
          });
        },
        child: const Icon(Icons.navigation),
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
    return CustomPaint(painter: BoardPainter(gameState));
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
        paint.color = ((i + j) % 2 == 0) ? Colors.lightBlue : Colors.lightGreen;
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

const List<String> kPlayerNames = <String>["Alice", "Bob"];
const List<Color> kPlayerColors = <Color>[Colors.purple, Colors.yellow];

class GameController {
  final Map<Player, Agent> _agents = <Player, Agent>{};

  GameController();

  factory GameController.random(int playerCount) {
    var controller = GameController();
    for (var i = 0; i < playerCount; ++i) {
      var player = Player(kPlayerNames[i], kPlayerColors[i]);
      controller.addPlayerWithAgent(player, agents.RandomMover());
    }
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

// Goals:
// Draw a board
// GameState object
// Take turns / query the agent for a move.
// Write an "agent" / "piece"
