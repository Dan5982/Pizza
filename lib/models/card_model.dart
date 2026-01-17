import 'stats.dart';

enum DueStatus { overdue, dueSoon, notDue }

class CardModel {
  final String id;
  final String title;
  final String pgnText;
  final int box;
  final int cursorPly;
  final DateTime dueAt;
  final Stats stats;

  CardModel({
    required this.id,
    required this.title,
    required this.pgnText,
    required this.box,
    required this.cursorPly,
    required this.dueAt,
    required this.stats,
  });

  factory CardModel.newCard({required String title, required String pgnText}) {
    return CardModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      pgnText: pgnText,
      box: 1,
      cursorPly: 0,
      dueAt: DateTime.now(),
      stats: Stats.empty(),
    );
  }

  DueStatus get dueStatus {
    final now = DateTime.now();
    if (dueAt.isBefore(now) || dueAt.isAtSameMomentAs(now)) {
      return DueStatus.overdue;
    }
    final soon = now.add(const Duration(hours: 6));
    if (dueAt.isBefore(soon)) {
      return DueStatus.dueSoon;
    }
    return DueStatus.notDue;
  }

  CardModel copyWith({
    String? title,
    String? pgnText,
    int? box,
    int? cursorPly,
    DateTime? dueAt,
    Stats? stats,
  }) {
    return CardModel(
      id: id,
      title: title ?? this.title,
      pgnText: pgnText ?? this.pgnText,
      box: box ?? this.box,
      cursorPly: cursorPly ?? this.cursorPly,
      dueAt: dueAt ?? this.dueAt,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pgnText': pgnText,
        'box': box,
        'cursorPly': cursorPly,
        'dueAt': dueAt.toIso8601String(),
        'stats': stats.toJson(),
      };

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        id: json['id'] as String,
        title: json['title'] as String,
        pgnText: json['pgnText'] as String,
        box: json['box'] as int? ?? 1,
        cursorPly: json['cursorPly'] as int? ?? 0,
        dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ?? DateTime.now(),
        stats: Stats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      );
}
