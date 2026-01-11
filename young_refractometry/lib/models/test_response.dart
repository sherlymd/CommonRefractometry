class TestResponse {
  final int round;
  final double blurLevel;
  final bool correct;
  final int responseTime;
  final String direction;
  final String userDirection;
  final String eye; // ADD THIS

  TestResponse({
    required this.round,
    required this.blurLevel,
    required this.correct,
    required this.responseTime,
    required this.direction,
    required this.userDirection,
    required this.eye, // ADD THIS
  });

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'blurLevel': blurLevel,
      'correct': correct,
      'responseTime': responseTime,
      'direction': direction,
      'userDirection': userDirection,
      'eye': eye, // ADD THIS
    };
  }
}