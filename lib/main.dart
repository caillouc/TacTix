import 'package:flutter/material.dart';
import 'package:tac_tics/src/rust/api/game.dart';
import 'package:tac_tics/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TacTics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  UtttGame? game;
  BigInt? crosses;
  BigInt? noughts;
  int? bigGame;
  GameState? gameState;
  List<GridPosition>? validMoves;

  List<GridPosition> moveHistory = [];
  List<List<GridPosition>?> validMovesHistory = [];
  List<bool> turnHistory = [];
  bool isRobotMode = false;
  bool isAiPlaying = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final newGame = await UtttGame.newInstance();
    await _updateState(newGame);
    setState(() {
      game = newGame;
      validMoves = null;
      moveHistory = [];
      validMovesHistory = [];
      turnHistory = [];
      isAiPlaying = false;
    });
  }

  Future<void> _updateState(UtttGame gameInstance) async {
    final c = gameInstance.crosses;
    final n = gameInstance.noughts;
    final bg = gameInstance.bigGame;
    final s = gameInstance.state;
    setState(() {
      crosses = c;
      noughts = n;
      bigGame = bg;
      gameState = s;
    });
  }

  Future<void> _handleTap(int gridIndex, int cellIndex) async {
    if (game == null || isAiPlaying) return;

    // Determine who is playing based on current state
    bool isCrossPlaying = gameState == GameState.crossesTurn;

    // Only allow move if it's someone's turn
    if (gameState != GameState.crossesTurn &&
        gameState != GameState.noughtsTurn) {
      return;
    }

    if (isRobotMode && !isCrossPlaying) return;

    final tappedPos = GridPosition(grid: gridIndex, posInGrid: cellIndex);

    // Check if move is valid
    if (validMoves != null && !validMoves!.contains(tappedPos)) {
      return;
    }

    await _executeMove(tappedPos, isCrossPlaying);
  }

  Future<void> _executeMove(GridPosition pos, bool isCrossPlaying) async {
    moveHistory.add(pos);
    validMovesHistory.add(validMoves);
    turnHistory.add(isCrossPlaying);

    // Call play
    final nextMoves = await game!.play(cell: pos, crossPlaying: isCrossPlaying);

    // Update UI
    await _updateState(game!);
    setState(() {
      validMoves = nextMoves;
    });

    if (isRobotMode && gameState == GameState.noughtsTurn) {
      _playAi();
    }
  }

  Future<void> _playAi() async {
    if (game == null) return;
    setState(() {
      isAiPlaying = true;
    });

    // Small delay for UX
    // await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Calculate available moves if validMoves is null
      List<GridPosition> availableMoves = List.from(validMoves ?? []);

      // Call AI play
      final playedPos = await game!.aiPlay(
        availableMove: availableMoves,
        crossPlaying: false, // AI is Noughts
      );

      // Execute the move
      await _executeMove(playedPos, false);
    } finally {
      if (mounted) {
        setState(() {
          isAiPlaying = false;
        });
      }
    }
  }

  Future<void> _undoLastMove() async {
    if (game == null || moveHistory.isEmpty || isAiPlaying) return;

    final lastMove = moveHistory.removeLast();
    final lastValidMoves = validMovesHistory.removeLast();
    final wasCross = turnHistory.removeLast();

    await game!.undo(cell: lastMove, crossMove: wasCross);

    await _updateState(game!);
    setState(() {
      validMoves = lastValidMoves;
    });
  }

  void _toggleRobotMode() {
    setState(() {
      isRobotMode = !isRobotMode;
    });
    if (isRobotMode && gameState == GameState.noughtsTurn) {
      _playAi();
    }
  }

  Set<int> _getWinningGrids() {
    if (bigGame == null) return {};

    Set<int> winningGrids = {};

    // Helper to check lines
    void check(int mask, int offset) {
      final playerMask = (bigGame! >> offset) & 511; // 9 bits

      final lines = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
        [0, 4, 8], [2, 4, 6], // Diagonals
      ];

      for (final line in lines) {
        bool isWin = true;
        for (final index in line) {
          if ((playerMask >> index) & 1 == 0) {
            isWin = false;
            break;
          }
        }
        if (isWin) {
          winningGrids.addAll(line);
        }
      }
    }

    if (gameState == GameState.crosssesWin) {
      check(bigGame!, 0);
    } else if (gameState == GameState.noughtsWin) {
      check(bigGame!, 9);
    }

    return winningGrids;
  }

  @override
  Widget build(BuildContext context) {
    if (game == null || crosses == null || noughts == null || bigGame == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(
                child: Text(
                  'TacTix',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGameStateHeader(),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: List.generate(3, (row) {
                            return Expanded(
                              child: Row(
                                children: List.generate(3, (col) {
                                  final gridIndex = row * 3 + col;
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          width: 2,
                                        ),
                                      ),
                                      child: _buildSubGrid(gridIndex),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Builder(
                      builder: (context) {
                        final iconColor =
                            IconTheme.of(context).color ??
                            Theme.of(context).iconTheme.color ??
                            Theme.of(context).colorScheme.onSurface;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.psychology, size: 32, color: iconColor),
                            if (!isRobotMode)
                              Transform.rotate(
                                angle: -0.785,
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  color: iconColor,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    onPressed: moveHistory.isEmpty ? _toggleRobotMode : null,
                    tooltip: 'AI Mode',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 32),
                    onPressed: _initGame,
                    tooltip: 'New Game',
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, size: 32),
                    onPressed: moveHistory.isEmpty ? null : _undoLastMove,
                    tooltip: 'Undo',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStateHeader() {
    String text = "";
    IconData? icon;
    Color? color;

    if (gameState == GameState.crossesTurn) {
      text = "Crosses Turn";
      icon = Icons.close_rounded;
      color = Colors.red;
    } else if (gameState == GameState.noughtsTurn) {
      text = "Noughts Turn";
      icon = Icons.circle_outlined;
      color = Colors.blue;
    } else if (gameState == GameState.crosssesWin) {
      text = "Crosses Win!";
      icon = Icons.close_rounded;
      color = Colors.green;
    } else if (gameState == GameState.noughtsWin) {
      text = "Noughts Win!";
      icon = Icons.circle_outlined;
      color = Colors.green;
    } else if (gameState == GameState.tie) {
      text = "Tie!";
      icon = Icons.balance;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: color, size: 32),
          if (icon != null) const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubGrid(int gridIndex) {
    // Check if subgrid is won
    final isWonByCross = (bigGame! >> gridIndex) & 1 == 1;
    final isWonByNought = (bigGame! >> (gridIndex + 9)) & 1 == 1;

    final winningGrids = _getWinningGrids();
    final isWinningGrid = winningGrids.contains(gridIndex);

    // Determine if subgrid is playable
    bool isSubgridPlayable = false;
    if (gameState == GameState.crossesTurn ||
        gameState == GameState.noughtsTurn) {
      if (validMoves == null) {
        isSubgridPlayable = true;
      } else {
        isSubgridPlayable = validMoves!.any((pos) => pos.grid == gridIndex);
      }
    }

    final backgroundColor = isSubgridPlayable
        ? null
        : Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    if (isWonByCross) {
      return Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(4.0),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.close_rounded,
            color: isWinningGrid ? Colors.green : Colors.red,
          ),
        ),
      );
    }
    if (isWonByNought) {
      return Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(4.0),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.circle_outlined,
            color: isWinningGrid ? Colors.green : Colors.blue,
          ),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                final cellIndex = row * 3 + col;
                final globalIndex = gridIndex * 9 + cellIndex;

                // Check if bit is set
                final isCross =
                    (crosses! >> globalIndex) & BigInt.one == BigInt.one;
                final isNought =
                    (noughts! >> globalIndex) & BigInt.one == BigInt.one;

                Widget? content;
                if (isCross) {
                  content = const FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(Icons.close_rounded, color: Colors.red),
                  );
                } else if (isNought) {
                  content = const FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(Icons.circle_outlined, color: Colors.blue),
                  );
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _handleTap(gridIndex, cellIndex),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      padding: const EdgeInsets.all(2.0),
                      child: content,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
