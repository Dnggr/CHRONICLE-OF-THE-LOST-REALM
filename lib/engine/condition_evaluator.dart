import '../models/character_state.dart';
import '../models/world_history.dart';

/// Evaluates the small condition-expression language used in scene JSON.
///
/// Supported forms (whitespace-insensitive):
///   flags.<key> == true
///   flags.<key> == false
///   flags.<key> == 'someString'
///   inventory.contains('itemName')
///   gold >= 15                         (also <=, >, <, ==)
///   attributes.<key> >= 12            (also <=, >, <, ==)
///   origin.<tag> == true              (also == false) - checks the archetype/
///                                      background/trait the player chose at
///                                      creation, e.g. "origin.royal == true"
///   reputation.<track> >= 3           (also <=, >, <, ==; negative values
///                                      allowed, e.g. "reputation.honor < -2")
///                                      tracks: honor, infamy, crown,
///                                      commonfolk (see Story & Systems Bible
///                                      section 4)
///   npc.<npc_id>.trust >= 3           (also <=, >, <, ==; negative allowed)
///   npc.<npc_id>.status == 'dead'     absent from CharacterState.npcStatus
///                                      implicitly means 'alive'
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

    // PROBLEM: a choice could promise "-15 Gold" yet still be offered to
    // a hero with less than 15 gold; applying the effect then created a
    // negative balance and let the player buy help they could not afford.
    // SOLUTION: expose the current gold balance to scene conditions, so
    // authored paid choices can be hidden unless the hero can pay them.
    final goldCompare = RegExp(
      r"^gold\s*(>=|<=|>|<|==)\s*(-?\d+)$",
    ).firstMatch(expr);
    if (goldCompare != null) {
      final op = goldCompare.group(1)!;
      final value = int.parse(goldCompare.group(2)!);
      return _compareInt(character.gold, op, value);
    }

    // PROBLEM: after adding Archetypes (Royal Heir, Vampire, Elf, etc),
    // scene writers needed a way to gate content on WHICH origin the
    // player picked, separate from world_flags (which are global/shared
    // across every playthrough) and separate from attribute checks
    // (which can be true for any build that rolls well, not just one
    // origin). SOLUTION: mirror the flags.<key> syntax but read from
    // CharacterState.originTags instead of WorldHistory.worldFlags.
    // Example usage in scene JSON: "origin.royal == true"
    final originBool = RegExp(
      r"^origin\.(\w+)\s*==\s*(true|false)$",
    ).firstMatch(expr);
    if (originBool != null) {
      final tag = originBool.group(1)!;
      final expected = originBool.group(2) == 'true';
      final actual = character.originTags.contains(tag);
      return actual == expected;
    }

    final attrCompare = RegExp(
      r"^attributes\.(\w+)\s*(>=|<=|>|<|==)\s*(\d+)$",
    ).firstMatch(expr);
    if (attrCompare != null) {
      final key = attrCompare.group(1)!;
      final op = attrCompare.group(2)!;
      final value = int.parse(attrCompare.group(3)!);
      final actual = character.attributes[key] ?? 0;
      return _compareInt(actual, op, value);
    }

    // PROBLEM (Story & Systems Bible, section 4): a single global honor
    // number can't represent a player who is simultaneously trusted by
    // common folk, feared by the crown, and notorious. SOLUTION: four
    // independent reputation tracks on CharacterState.reputation, each
    // checkable the same way attributes are, including negative values
    // (reputation can go below zero, unlike core stats).
    final reputationCompare = RegExp(
      r"^reputation\.(\w+)\s*(>=|<=|>|<|==)\s*(-?\d+)$",
    ).firstMatch(expr);
    if (reputationCompare != null) {
      final track = reputationCompare.group(1)!;
      final op = reputationCompare.group(2)!;
      final value = int.parse(reputationCompare.group(3)!);
      final actual = character.reputation[track] ?? 0;
      return _compareInt(actual, op, value);
    }

    // PROBLEM: reputation tracks above are PUBLIC (how strangers react
    // on first meeting) - the bible also calls for PRIVATE, per-NPC
    // trust that doesn't leak into public opinion (you can be forgiven
    // by one specific person you wronged while everyone else still
    // distrusts you). SOLUTION: CharacterState.npcTrust, keyed by the
    // npc_id values defined in lib/data/npcs.dart.
    final npcTrustCompare = RegExp(
      r"^npc\.(\w+)\.trust\s*(>=|<=|>|<|==)\s*(-?\d+)$",
    ).firstMatch(expr);
    if (npcTrustCompare != null) {
      final npcId = npcTrustCompare.group(1)!;
      final op = npcTrustCompare.group(2)!;
      final value = int.parse(npcTrustCompare.group(3)!);
      final actual = character.npcTrust[npcId] ?? 0;
      return _compareInt(actual, op, value);
    }

    // Per-NPC status (alive/dead/estranged/turned_enemy/...). Absence
    // from npcStatus means 'alive' - see CharacterState.npcStatus's doc
    // comment for why only CHANGED statuses need an entry.
    final npcStatusCompare = RegExp(
      r"^npc\.(\w+)\.status\s*==\s*'([^']*)'$",
    ).firstMatch(expr);
    if (npcStatusCompare != null) {
      final npcId = npcStatusCompare.group(1)!;
      final expected = npcStatusCompare.group(2)!;
      final actual = character.npcStatus[npcId] ?? 'alive';
      return actual == expected;
    }

    // Unknown expression format - fail safe by hiding the content rather
    // than crashing the game. Check your JSON syntax against the
    // patterns documented above if a choice/variant is missing.
    return false;
  }

  static bool _compareInt(int actual, String op, int value) {
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
      default:
        return false;
    }
  }
}
