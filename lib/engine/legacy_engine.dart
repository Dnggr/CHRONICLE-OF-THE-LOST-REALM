import '../data/archetypes.dart';
import '../models/character_state.dart';
import '../models/world_history.dart';
import 'save_manager.dart';

/// Handles the death -> canon -> new run pipeline described in the plan.
class LegacyEngine {
  /// Call this the moment a character dies (health hits 0, age hits
  /// maxAge, or a fatal choice is taken). Builds a DeceasedHero record
  /// from the run, appends it to WorldHistory, applies any pending
  /// world-flag changes, and persists both.
  static Future<WorldHistory> recordDeath({
    required CharacterState character,
    required WorldHistory world,
    required String causeOfDeath,
    String? title,
    String alignment = 'Neutral',
    String graveLocation = 'An unmarked grave',
  }) async {
    // PROBLEM: this used to hardcode title: 'The Wanderer' for every
    // deceased hero, which was wrong the moment Archetypes shipped - a
    // dead Royal Heir or Vampire shouldn't be remembered as "The
    // Wanderer" in the Chronicle. SOLUTION: if no explicit title is
    // passed, derive one from the archetype the player actually picked.
    // originTags[0] is always the archetype's own id by convention (see
    // CharacterState.fromArchetype), so we look it up in the Archetypes
    // registry for its display name.
    final resolvedTitle = title ?? _titleFromOrigin(character.originTags);

    final hero = DeceasedHero(
      heroId: 'hero_${DateTime.now().millisecondsSinceEpoch}',
      name: character.name,
      title: resolvedTitle,
      causeOfDeath: causeOfDeath,
      yearOfDeath: world.currentYear,
      ageAtDeath: character.age,
      alignment: alignment,
      graveLocation: graveLocation,
      relicsLeft: List<String>.from(character.inventory),
      majorCanonEvents: List<String>.from(character.runHistory),
    );

    world.deceasedHeroes.add(hero);
    world.currentYear += 1;

    await SaveManager.saveWorld(world);
    await SaveManager.clearRun();

    return world;
  }

  /// Applies a single world-flag change. Call this from wherever a
  /// SceneChoice.effects map is processed, e.g.
  /// effects: { "world_flags.sun_temple_destroyed": true }
  static void applyFlagEffect(
    WorldHistory world,
    String key,
    dynamic value,
  ) {
    world.worldFlags[key] = value;
  }

  static String _titleFromOrigin(List<String> originTags) {
    if (originTags.isEmpty) return 'The Adventurer';
    final archetypeId = originTags.first;
    for (final archetype in Archetypes.all) {
      if (archetype.id == archetypeId) return archetype.displayName;
    }
    return 'The Adventurer';
  }

  // NOTE: the old generic startNewRun({name}) factory was removed here -
  // character creation now always goes through
  // CharacterState.fromArchetype(name, archetype) so that archetype
  // perks (stats/gear/gold/origin tags) can never accidentally be
  // skipped. See CharacterCreationScreen + GameController.beginRun().
}
