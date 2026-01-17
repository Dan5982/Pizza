import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess;

import '../models/card_model.dart';
import '../services/pgn_service.dart';

class MoveOutcome {
  final bool isLegal;
  final bool isCorrect;
  final String? fenAfter;
  final String? errorMessage;

  const MoveOutcome({
    required this.isLegal,
    required this.isCorrect,
    this.fenAfter,
    this.errorMessage,
  });
}

class LeitnerScheduler {
  static DateTime nextDueDate(int box, DateTime from) {
    switch (box) {
      case 1:
        return from;
      case 2:
        return from.add(const Duration(hours: 8));
      case 3:
        return from.add(const Duration(days: 1));
      case 4:
        return from.add(const Duration(days: 3));
      case 5:
        return from.add(const Duration(days: 7));
      default:
        return from.add(const Duration(days: 14));
    }
  }
}

class TrainerEngine extends ChangeNotifier {
  final PGNService _pgnService;
  final Map<int, String> _overrideComments;

  CardModel card;
  int currentPly;
  String statusText;
  String? errorText;
  String? annotationText;
  int totalPlies;
  String boardFEN;

  late final List<String> _expectedMoves;
  late final List<String> _expectedFENs;
  late final Map<int, String> _commentsByPly;

  final dynamic _game = chess.Chess();

  TrainerEngine({
    required this.card,
    PGNService? pgnService,
    Map<int, String> overrideComments = const {},
  })  : _pgnService = pgnService ?? PGNService(),
        _overrideComments = overrideComments,
        currentPly = card.cursorPly,
        statusText = 'Play the expected move.',
        totalPlies = 0,
        boardFEN = '' {
    final parsed = _pgnService.parse(card.pgnText);
    totalPlies = parsed.moves.length;
    _expectedMoves = parsed.moves;
    _commentsByPly = parsed.commentsByPly;
    _expectedFENs = _buildExpectedFENs(parsed.moves);
    _resetGame();
    if (_expectedFENs.isNotEmpty) {
      boardFEN = _expectedFENs.first;
      _loadFen(boardFEN);
    }
  }

  void restart({required int autoPlies}) {
    currentPly = card.cursorPly;
    errorText = null;
    annotationText = null;
    statusText = 'Play the expected move.';
    _resetGame();

    final autoCount = autoPlies.clamp(0, totalPlies);
    if (_expectedFENs.isNotEmpty && autoCount > 0) {
      final targetIndex = (autoCount - 1).clamp(0, _expectedFENs.length - 1);
      boardFEN = _expectedFENs[targetIndex];
      _loadFen(boardFEN);
      currentPly = autoCount;
    }
    notifyListeners();
  }

  MoveOutcome attemptMove({
    required String from,
    required String to,
    String? promotion,
  }) {
    if (totalPlies == 0) {
      statusText = 'No moves parsed.';
      notifyListeners();
      return const MoveOutcome(isLegal: false, isCorrect: false);
    }

    final moveResult = _game.move({
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    });

    if (moveResult == null) {
      errorText = 'Illegal move. Try again.';
      notifyListeners();
      return const MoveOutcome(
        isLegal: false,
        isCorrect: false,
        errorMessage: 'Illegal move.',
      );
    }

    final fenAfter = _fenFromGame(_game);
    final expectedFen = currentPly < _expectedFENs.length
        ? _expectedFENs[currentPly]
        : null;
    final expectedMove = currentPly < _expectedMoves.length
        ? _expectedMoves[currentPly]
        : '';
    final sanMove = _extractSan(moveResult);

    final isCorrect = expectedFen != null
        ? expectedFen == fenAfter
        : _normalizeSan(expectedMove) == _normalizeSan(sanMove);

    _applyResult(isCorrect);
    boardFEN = fenAfter;
    notifyListeners();

    return MoveOutcome(
      isLegal: true,
      isCorrect: isCorrect,
      fenAfter: fenAfter,
    );
  }

  void _applyResult(bool isCorrect) {
    final now = DateTime.now();
    var updatedStats = card.stats.copyWith(
      attempts: card.stats.attempts + 1,
      lastSeen: now,
    );

    if (isCorrect) {
      errorText = null;
      updatedStats = updatedStats.copyWith(
        correct: updatedStats.correct + 1,
      );
      currentPly += 1;
      var updatedCard = card.copyWith(
        cursorPly: currentPly,
        stats: updatedStats,
      );
      statusText = 'Correct. Play the next move.';
      annotationText = _overrideComments[currentPly - 1] ??
          _commentsByPly[currentPly - 1];

      if (currentPly >= totalPlies) {
        final nextBox = (updatedCard.box + 1).clamp(1, 6);
        updatedCard = updatedCard.copyWith(
          box: nextBox,
          cursorPly: 0,
          dueAt: LeitnerScheduler.nextDueDate(nextBox, now),
        );
        currentPly = 0;
        statusText = 'Line complete. Box advanced to $nextBox.';
        _resetGame();
      }
      card = updatedCard;
    } else {
      statusText = 'Play the expected move.';
      errorText = 'Incorrect move. Line reset to box 1.';
      annotationText = null;
      currentPly = 0;
      card = card.copyWith(
        box: 1,
        cursorPly: 0,
        dueAt: now.add(const Duration(minutes: 10)),
        stats: updatedStats.copyWith(wrong: updatedStats.wrong + 1),
      );
      _resetGame();
    }
  }

  List<String> _buildExpectedFENs(List<String> moves) {
    final fens = <String>[];
    final dynamic expectedGame = chess.Chess();
    for (final move in moves) {
      final result = expectedGame.move(move, sloppy: true);
      if (result == null) break;
      fens.add(_fenFromGame(expectedGame));
    }
    return fens;
  }

  void _resetGame() {
    _game.reset();
    boardFEN = _fenFromGame(_game);
  }

  void _loadFen(String fen) {
    try {
      _game.load(fen);
      return;
    } catch (_) {}
    try {
      _game.load_fen(fen);
    } catch (_) {}
  }

  String _normalizeSan(String san) {
    return san.replaceAll('+', '').replaceAll('#', '').trim();
  }

  String _extractSan(dynamic moveResult) {
    if (moveResult is Map && moveResult['san'] != null) {
      return moveResult['san'].toString();
    }
    return moveResult?.toString() ?? '';
  }

  String _fenFromGame(dynamic game) {
    try {
      final fenValue = game.fen;
      if (fenValue is String) {
        return fenValue;
      }
      if (fenValue is Function) {
        return fenValue();
      }
    } catch (_) {}
    return game.fen();
  }
}
