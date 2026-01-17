class Stats {
  final int attempts;
  final int correct;
  final int wrong;
  final DateTime? lastSeen;

  const Stats({
    required this.attempts,
    required this.correct,
    required this.wrong,
    required this.lastSeen,
  });

  factory Stats.empty() => const Stats(
        attempts: 0,
        correct: 0,
        wrong: 0,
        lastSeen: null,
      );

  Stats copyWith({
    int? attempts,
    int? correct,
    int? wrong,
    DateTime? lastSeen,
  }) {
    return Stats(
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'correct': correct,
        'wrong': wrong,
        'lastSeen': lastSeen?.toIso8601String(),
      };

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        attempts: json['attempts'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        wrong: json['wrong'] as int? ?? 0,
        lastSeen: json['lastSeen'] != null
            ? DateTime.tryParse(json['lastSeen'] as String)
            : null,
      );
}
