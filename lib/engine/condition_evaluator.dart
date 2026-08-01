import '../models/character_state.dart';
import '../models/world_history.dart';

/// Evaluates the small condition-expression language used in scene JSON.
///
/// Supported forms (whitespace-insensitive):
///   flags.<key> == true
///   flags.<key> == false
///   flags.<key> == 'someString'
///   inventory.contains('itemName')
///   attributes.<key> >= 12        (also <=, >, <, ==)
///
/// This is intentionally NOT a full expression parser - it covers the
/// handful of patterns the game actually needs. If you find yourself
/// wanting AND/OR combinators, either add a second condition field
/// (conditionAll: [...]) rather than growing this into a real parser,
/// or write a second expression and check both from Dart.
class ConditionEvaluator {
  final CharacterState character;
  final WorldHistory world;

  ConditionEvaluator({required this.character, required this.world});

  bool evaluate(String? expression) {
    if (expression == null || expression.trim().isEmpty) return true;
    final expr = expression.trim();

    final flagBool = RegExp(
      r"^flags\.(\w+)\s*==\s*(true|false)$",
    ).firstMatch(expr);
    if (flagBool != null) {
      final key = flagBool.group(1)!;
      final expected = flagBool.group(2) == 'true';
      final actual = world.worldFlags[key] == true;
      return actual == expected;
    }

    final flagString = RegExp(
      r"^flags\.(\w+)\s*==\s*'([^']*)'$",
    ).firstMatch(expr);
    if (flagString != null) {
      final key = flagString.group(1)!;
      final expected = flagString.group(2)!;
      return world.worldFlags[key] == expected;
    }

    final invContains = RegExp(
      r"^inventory\.contains\('([^']*)'\)$",
    ).firstMatch(expr);
    if (invContains != null) {
      final item = invContains.group(1)!;
      return character.inventory.contains(item);
    }

    final attrCompare = RegExp(
      r"^attributes\.(\w+)\s*(>=|<=|>|<|==)\s*(\d+)$",
    ).firstMatch(expr);
    if (attrCompare != null) {
      final key = attrCompare.group(1)!;
      final op = attrCompare.group(2)!;
      final value = int.parse(attrCompare.group(3)!);
      final actual = character.attributes[key] ?? 0;
      switch (op) {
        case '>=':
          return actual >= value;
        case '<=':
          return actual <= value;
        case '>':
          return actual > value;
        case '<':
          return actual < value;
        case '==':
          return actual == value;
      }
    }

    // Unknown expression format - fail safe by hiding the content rather
    // than crashing the game. Check your JSON syntax against the
    // patterns documented above if a choice/variant is missing.
    return false;
  }
}
