import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire_trainer/training/trainer_engine.dart';

void main() {
  test('LeitnerScheduler schedules next due dates', () {
    final base = DateTime(2024, 1, 1, 12);
    expect(LeitnerScheduler.nextDueDate(1, base), base);
    expect(LeitnerScheduler.nextDueDate(2, base), base.add(const Duration(hours: 8)));
    expect(LeitnerScheduler.nextDueDate(3, base), base.add(const Duration(days: 1)));
    expect(LeitnerScheduler.nextDueDate(4, base), base.add(const Duration(days: 3)));
    expect(LeitnerScheduler.nextDueDate(5, base), base.add(const Duration(days: 7)));
    expect(LeitnerScheduler.nextDueDate(6, base), base.add(const Duration(days: 14)));
  });
}
