import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../storage/card_store.dart';
import '../training/trainer_engine.dart';

class TrainScreen extends StatefulWidget {
  final CardModel card;

  const TrainScreen({super.key, required this.card});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  late TrainerEngine engine;
  int autoPlies = 3;

  @override
  void initState() {
    super.initState();
    engine = TrainerEngine(card: widget.card);
    engine.addListener(_persistCard);
    engine.restart(autoPlies: autoPlies);
  }

  void _persistCard() {
    context.read<CardStore>().updateCard(engine.card);
  }

  @override
  void dispose() {
    engine.removeListener(_persistCard);
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.title),
      ),
      body: AnimatedBuilder(
        animation: engine,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ChessBoardWidget(
                fen: engine.boardFEN,
                onMove: (from, to) {
                  engine.attemptMove(from: from, to: to);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Ply ${engine.currentPly} of ${engine.totalPlies}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                engine.statusText,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              if (engine.errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  engine.errorText!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
              if (engine.annotationText != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Annotation',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(engine.annotationText ?? ''),
              ],
              const SizedBox(height: 16),
              Text('Auto plies: $autoPlies'),
              Slider(
                value: autoPlies.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '$autoPlies',
                onChanged: (value) {
                  setState(() {
                    autoPlies = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => engine.restart(autoPlies: autoPlies),
                    child: const Text('Restart'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Library'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final void Function(String from, String to) onMove;

  const ChessBoardWidget({super.key, required this.fen, required this.onMove});

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  String? selectedSquare;

  @override
  Widget build(BuildContext context) {
    final board = _fenToBoard(widget.fen);
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: (context, index) {
          final row = index ~/ 8;
          final col = index % 8;
          final square = _squareName(row, col);
          final piece = board[row][col];
          final isLight = (row + col) % 2 == 0;
          final isSelected = selectedSquare == square;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selectedSquare == null) {
                  if (piece.isNotEmpty) {
                    selectedSquare = square;
                  }
                } else if (selectedSquare == square) {
                  selectedSquare = null;
                } else {
                  final from = selectedSquare!;
                  final to = square;
                  selectedSquare = null;
                  widget.onMove(from, to);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.yellow.shade300
                    : isLight
                        ? Colors.brown.shade200
                        : Colors.brown.shade600,
              ),
              child: Center(
                child: Text(
                  _pieceSymbol(piece),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<List<String>> _fenToBoard(String fen) {
    final rows = fen.split(' ').first.split('/');
    final board = List.generate(8, (_) => List.filled(8, ''));
    for (var r = 0; r < 8; r++) {
      var file = 0;
      for (final char in rows[r].split('')) {
        final digit = int.tryParse(char);
        if (digit != null) {
          file += digit;
        } else {
          board[r][file] = char;
          file += 1;
        }
      }
    }
    return board;
  }

  String _squareName(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  String _pieceSymbol(String piece) {
    switch (piece) {
      case 'P':
        return '♙';
      case 'N':
        return '♘';
      case 'B':
        return '♗';
      case 'R':
        return '♖';
      case 'Q':
        return '♕';
      case 'K':
        return '♔';
      case 'p':
        return '♟︎';
      case 'n':
        return '♞';
      case 'b':
        return '♝';
      case 'r':
        return '♜';
      case 'q':
        return '♛';
      case 'k':
        return '♚';
      default:
        return '';
    }
  }
}
