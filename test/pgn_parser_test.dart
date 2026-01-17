import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire_trainer/services/pgn_service.dart';

void main() {
  test('Fallback PGN parser extracts mainline moves and comments', () {
    const pgn = '[Event "Training"]\n1. e4 e5 2. Nf3 Nc6 {Mainline comment} 3. Bb5 a6 (3... Nf6) 1-0';
    final result = PGNService().parse(pgn);
    expect(result.moves, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6']);
    expect(result.commentsByPly[3], 'Mainline comment');
  });
}
