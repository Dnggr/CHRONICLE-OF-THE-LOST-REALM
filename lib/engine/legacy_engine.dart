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
    String? alignment,
    String graveLocation = 'An unmarked grave',
  }) async {
    // PROBLEM: this used to hardcode title: 'The Wanderer' for every
    // deceased hero, which was wrong the moment Archetypes shipped - a
    // dead Royal Heir or Vampire shouldn't be remembered as "The
    // Wanderer" in the Chronicle. SOLUTION: if no explicit title is
    // passed, derive one from the archetype the player actually picked.
    // originTags[0] is always the archetype's own id by convention (see
    // CharacterState.fromCreationData), so we look it up in the
    // Archetypes registry for its display name.
    final resolvedTitle = title ?? _titleFromOrigin(character.originTags);

    // PROBLEM (Story & Systems Bible, section 4.3): "extreme reputation
    // states at time of death should feed into the DeceasedHero record
    // itself... giving FUTURE playthroughs' NPCs something specific to
    // react to." Previously `alignment` was always the hardcoded default
    // 'Neutral', regardless of how the character actually played.
    // SOLUTION: derive it from the four reputation tracks if the caller
    // doesn't explicitly override it, and append an extra canon phrase
    // for genuinely extreme cases (bible's own example: "Ruled through
    // fear, not law" for high-infamy/low-honor).
    final resolvedAlignment = alignment ?? _alignmentFromReputation(character.reputation);
    final canonEvents = List<String>.from(character.runHistory);
    final extremePhrase = _extremeReputationPhrase(character.reputation);
    if (extremePhrase != null) canonEvents.add(extremePhrase);

    final hero = DeceasedHero(
      heroId: 'hero_${DateTime.now().millisecondsSinceEpoch}',
      name: character.name,
      title: resolvedTitle,
      causeOfDeath: causeOfDeath,
      yearOfDeath: world.currentYear,
      ageAtDeath: character.age,
      alignment: resolvedAlignment,
      graveLocation: graveLocation,
      relicsLeft: List<String>.from(character.inventory),
      majorCanonEvents: canonEvents,
    );

    world.deceasedHeroes.add(hero);
    world.currentYear += 1;

    await SaveManager.saveWorld(world);
    await SaveManager.clearRun();

    return world;
  }

  /// Coarse honor/infamy -> alignment label. Deliberately simple (four
  /// buckets) rather than trying to capture the full nuance the
  /// reputation system allows - DeceasedHero.alignment is a short
  /// display label, not the reputation system itself; the full nuance
  /// still lives in the majorCanonEvents phrase below and in whatever
  /// the Journal/History screens choose to surface later.
  static String _alignmentFromReputation(Map<String, int> reputation) {
    final honor = reputation['honor'] ?? 0;
    final infamy = reputation['infamy'] ?? 0;
    if (honor >= 5 && infamy < 5) return 'Honorable';
    if (infamy >= 5 && honor < 0) return 'Feared';
    if (honor < -3) return 'Ruthless';
    return 'Neutral';
  }

  /// Returns an extra canon-event phrase for genuinely extreme
  /// reputation states, or null for ordinary ones - most characters
  /// should NOT get one of these; it's meant to read as notable.
  static String? _extremeReputationPhrase(Map<String, int> reputation) {
    final honor = reputation['honor'] ?? 0;
    final infamy = reputation['infamy'] ?? 0;
    final crown = reputation['crown'] ?? 0;
    final commonfolk = reputation['commonfolk'] ?? 0;

    if (infamy >= 10 && honor <= -5) return 'Ruled through fear, not law';
    if (honor >= 10 && commonfolk >= 8) return 'Died beloved by the common folk';
    if (commonfolk >= 8 && crown <= -8) {
      return 'Championed the people against the crown';
    }
    if (crown >= 8 && commonfolk <= -8) {
      return "Served the crown at the people's expense";
    }
    if (honor >= 8 && infamy >= 8) return 'Became a legend both loved and feared';
    return null;
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
  // CharacterState.fromCreationData(...) so that archetype/background/
  // perks (stats/gear/gold/origin tags) can never accidentally be
  // skipped. See CharacterCreationScreen + GameController.beginRun().
}
