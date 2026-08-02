import 'package:flutter_test/flutter_test.dart';
import 'package:lost_realm/engine/condition_evaluator.dart';
import 'package:lost_realm/models/character_state.dart';
import 'package:lost_realm/models/world_history.dart';

void main() {
  test('scene conditions gate paid choices by the hero gold balance', () {
    // PROBLEM: the old generated counter test referenced MyApp, which does
    // not exist in this app, so `flutter test` could never pass. SOLUTION:
    // test a real, pure game rule instead: paid narrative choices only show
    // when the CharacterState can afford them.
    final character = CharacterState(name: 'Test Hero', gold: 14);
    final evaluator = ConditionEvaluator(
      character: character,
      world: WorldHistory(),
    );

    expect(evaluator.evaluate('gold >= 15'), isFalse);
    character.gold = 15;
    expect(evaluator.evaluate('gold >= 15'), isTrue);
  });
}
