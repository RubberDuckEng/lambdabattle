import 'package:flutter/material.dart';
import 'engine.dart';
import 'agents.dart';

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

class Board extends StatelessWidget {
  const Board({Key? key, required this.gameState}) : super(key: key);

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

// Goals:
// Draw a board
// GameState object
// Take turns / query the agent for a move.
// Write an "agent" / "piece"
