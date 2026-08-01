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
    String title = 'The Wanderer',
    String alignment = 'Neutral',
    String graveLocation = 'An unmarked grave',
  }) async {
    final hero = DeceasedHero(
      heroId: 'hero_${DateTime.now().millisecondsSinceEpoch}',
      name: character.name,
      title: title,
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

  /// Creates a fresh CharacterState to begin a new run. The opening
  /// scene id is fixed here (prologue_start); which NARRATIVE TEXT that
  /// scene shows is decided later by ConditionEvaluator + the scene's
  /// narrativeVariants, using data already sitting in [world].
  static CharacterState startNewRun({required String name}) {
    return CharacterState(name: name);
  }
}
