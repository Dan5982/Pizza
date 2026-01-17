import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class PGNParseResult {
  final List<String> moves;
  final Map<int, String> commentsByPly;

  const PGNParseResult({required this.moves, required this.commentsByPly});
}

class PGNService {
  PGNParseResult parse(String pgn) {
    return _FallbackPGNParser.parse(pgn);
  }

  Future<List<String>> listAssetPGNs() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final decoded = jsonDecode(manifest) as Map<String, dynamic>;
    return decoded.keys
        .where((key) => key.startsWith('assets/pgn/'))
        .toList()
      ..sort();
  }

  Future<String> loadAssetPGN(String assetPath) async {
    return rootBundle.loadString(assetPath);
  }
}

class _FallbackPGNParser {
  static PGNParseResult parse(String pgn) {
    final withoutTags = pgn
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('['))
        .join(' ');

    final withoutVariations = _stripVariations(withoutTags);
    final moves = <String>[];
    final commentsByPly = <int, String>{};

    final buffer = StringBuffer();
    final commentBuffer = StringBuffer();
    var inComment = false;

    void flushToken() {
      final token = buffer.toString().trim();
      buffer.clear();
      if (token.isEmpty) return;
      final cleaned = _trimMoveNumber(token);
      if (_isResultToken(cleaned)) return;
      if (cleaned.isNotEmpty) moves.add(cleaned);
    }

    for (final char in withoutVariations.split('')) {
      if (inComment) {
        if (char == '}') {
          inComment = false;
          final plyIndex = moves.isNotEmpty ? moves.length - 1 : 0;
          final comment = commentBuffer.toString().trim();
          if (comment.isNotEmpty) {
            commentsByPly.update(
              plyIndex,
              (value) => '$value $comment',
              ifAbsent: () => comment,
            );
          }
          commentBuffer.clear();
        } else {
          commentBuffer.write(char);
        }
        continue;
      }

      if (char == '{') {
        flushToken();
        inComment = true;
        continue;
      }

      if (char.trim().isEmpty) {
        flushToken();
      } else {
        buffer.write(char);
      }
    }
    flushToken();

    return PGNParseResult(moves: moves, commentsByPly: commentsByPly);
  }

  static String _stripVariations(String text) {
    final buffer = StringBuffer();
    var depth = 0;
    for (final char in text.split('')) {
      if (char == '(') {
        depth += 1;
        continue;
      }
      if (char == ')') {
        depth = depth > 0 ? depth - 1 : 0;
        continue;
      }
      if (depth == 0) buffer.write(char);
    }
    return buffer.toString();
  }

  static String _trimMoveNumber(String token) {
    final stripped = token.replaceAll('...', '');
    final isNumber = stripped.split('').every((char) =>
        char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57 || char == '.');
    if (isNumber) return '';
    final dotIndex = stripped.indexOf('.');
    if (dotIndex != -1 && dotIndex + 1 < stripped.length) {
      return stripped.substring(dotIndex + 1);
    }
    return stripped;
  }

  static bool _isResultToken(String token) {
    return const ['1-0', '0-1', '1/2-1/2', '*'].contains(token);
  }
}
