import 'dart:math';

class StatCheckResult {
  final int roll;
  final int modifier;
  final int total;
  final int difficultyClass;
  final bool success;

  const StatCheckResult({
    required this.roll,
    required this.modifier,
    required this.total,
    required this.difficultyClass,
    required this.success,
  });
}

class DiceRoller {
  final Random _random;

  DiceRoller({Random? random}) : _random = random ?? Random();

  /// Rolls 1d20, adds [modifier] (an attribute score, or a derived
  /// modifier if you switch to D&D-style (score-10)/2 later), and
  /// compares to [difficultyClass].
  StatCheckResult check({
    required int modifier,
    required int difficultyClass,
  }) {
    final roll = _random.nextInt(20) + 1; // 1-20
    final total = roll + modifier;
    return StatCheckResult(
      roll: roll,
      modifier: modifier,
      total: total,
      difficultyClass: difficultyClass,
      success: total >= difficultyClass,
    );
  }
}
