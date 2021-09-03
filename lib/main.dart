import 'package:flutter/material.dart';

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
  GameState gameState = GameState();
  GameController gameController = GameController();

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
          child: Board(
            gameState: gameState,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            gameState = gameController.takeTurn(gameState);
          });
        },
        child: const Icon(Icons.navigation),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class Position {
  final int x;
  final int y;

  Position(this.x, this.y);
}

class Player {
  // TODO: We should separate player from position and from piece.
  final Position position;
  final Color color;

  Player({required this.position, required this.color});

  Player move(Move move) {
    return Player(
      position: Position(position.x + move.dx, position.y + move.dy),
      color: color,
    );
  }
}

class GameState {
  final List<Player> players;
  final int currentPlayerIndex;

  int nextPlayerIndex() {
    return (currentPlayerIndex + 1) % players.length;
  }

  Player activePlayer() {
    return players[currentPlayerIndex];
  }

  GameState()
      : players = <Player>[
          Player(position: Position(0, 0), color: Colors.purple),
          Player(
              position: Position(kBoardWidth - 1, kBoardHeight - 1),
              color: Colors.amber)
        ],
        currentPlayerIndex = 0;

  GameState._(this.players, this.currentPlayerIndex);

  GameState afterMove(Move move) {
    var nextPlayers = List<Player>.from(players);
    nextPlayers[currentPlayerIndex] = activePlayer().move(move);
    return GameState._(nextPlayers, nextPlayerIndex());
  }
}

class Board extends StatelessWidget {
  const Board({Key? key, required this.gameState}) : super(key: key);

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: BoardPainter(gameState));
  }
}

const int kBoardWidth = 8;
const int kBoardHeight = 8;

class BoardPainter extends CustomPainter {
  final GameState gameState;

  BoardPainter(this.gameState);

  void paintBackground(Canvas canvas, Size size, Size cell) {
    var paint = Paint();
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < kBoardWidth; ++i) {
      for (int j = 0; j < kBoardHeight; ++j) {
        paint.color = ((i + j) % 2 == 0) ? Colors.lightBlue : Colors.lightGreen;
        canvas.drawRect(rectForPosition(Position(i, j), cell), paint);
      }
    }
  }

  Rect rectForPosition(Position position, Size cell) {
    return Rect.fromLTWH(position.x * cell.width, position.y * cell.height,
        cell.width, cell.height);
  }

  void paintPlayers(Canvas canvas, Size size, Size cell) {
    var paint = Paint();
    paint.style = PaintingStyle.fill;
    for (var player in gameState.players) {
      var position = player.position;
      paint.color = player.color;
      canvas.drawOval(rectForPosition(position, cell), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    var cellSize = Size(size.width / kBoardWidth, size.height / kBoardHeight);
    paintBackground(canvas, size, cellSize);
    paintPlayers(canvas, size, cellSize);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Move {
  final int dx;
  final int dy;

  Move(this.dx, this.dy);
}

class AgentBoardView {
  final GameState _gameState;
  final Player _player;

  AgentBoardView(this._gameState, this._player);

  bool isValidPosition(Position position) {
    return position.x >= 0 &&
        position.x < kBoardWidth &&
        position.y >= 0 &&
        position.y < kBoardHeight;
  }

  bool isValidMove(Move move) {
    var player = _player.move(move);
    return isValidPosition(player.position);
  }

  Iterable<Move> get validMoves sync* {
    for (int dx = -1; dx <= 1; ++dx) {
      for (int dy = -1; dy <= 1; ++dy) {
        // TODO: Should be checked by isValidMove.
        if (dx == 0 && dy == 0) {
          continue;
        }
        var move = Move(dx, dy);
        if (isValidMove(move)) {
          yield move;
        }
      }
    }
  }
}

abstract class Agent {
  Move pickMove(AgentBoardView view);
}

class FirstMover implements Agent {
  @override
  Move pickMove(AgentBoardView view) {
    return view.validMoves.first;
  }
}

class GameController {
  List<Agent> agents = <Agent>[FirstMover(), FirstMover()];

  Agent activeAgent(GameState gameState) {
    return agents[gameState.currentPlayerIndex];
  }

  GameState takeTurn(GameState gameState) {
    var agent = activeAgent(gameState);
    var view = AgentBoardView(gameState, gameState.activePlayer());
    var move = agent.pickMove(view);
    // TODO: Validate move?
    return gameState.afterMove(move);
  }
}

// Goals:
// Draw a board
// GameState object
// Take turns / query the agent for a move.
// Write an "agent" / "piece"
