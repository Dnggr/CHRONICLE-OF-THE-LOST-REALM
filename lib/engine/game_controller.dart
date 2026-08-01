import 'package:flutter/foundation.dart';

import '../data/archetypes.dart';
import '../data/scene_repository.dart';
import '../models/character_state.dart';
import '../models/scene_node.dart';
import '../models/world_history.dart';
import 'condition_evaluator.dart';
import 'dice_roller.dart';
import 'legacy_engine.dart';
import 'save_manager.dart';

/// The single source of truth the UI listens to. Owns the active
/// CharacterState, the permanent WorldHistory, and the scene graph.
///
/// CHANGE LOG (see /DEVLOG.md for the full narrative of each session):
/// - [character] used to be `late` and auto-filled with a generic
///   "Wanderer" the instant the app opened, before the user could pick
///   anything. PROBLEM: that made a real character-creation flow
///   impossible to insert cleanly - there was no "no character yet"
///   state for the UI to key off of. SOLUTION: character is now
///   nullable. `character == null` (and not dead) IS the signal that
///   means "show CharacterCreationScreen" - see [needsCharacterCreation]
///   below and _AppRoot in main.dart. This removes an entire class of
///   bugs where the UI had to track its own separate "have we shown
///   creation yet" boolean that could drift out of sync with the engine.
class GameController extends ChangeNotifier {
  final SceneRepository sceneRepository;
  final DiceRoller diceRoller;

  CharacterState? character;
  late WorldHistory world;
  SceneNode? currentScene;

  /// True once init() has finished loading scenes + save data. Lets the
  /// UI tell "still starting up" apart from "loaded, but no character
  /// exists yet" - both look like `character == null` otherwise.
  bool isLoaded = false;

  /// Set right after a stat check so the UI can show "Roll: 14 + 2 = 16
  /// vs DC 12 - Success!" before the player taps to continue.
  StatCheckResult? lastCheckResult;

  bool isDead = false;
  String? deathCause;

  GameController({
    required this.sceneRepository,
    DiceRoller? diceRoller,
  }) : diceRoller = diceRoller ?? DiceRoller();

  /// True when the UI should show CharacterCreationScreen: either this
  /// is a fresh install with no saved run, or the previous character
  /// just died and acknowledgeDeath() has been called.
  bool get needsCharacterCreation => isLoaded && character == null && !isDead;

  Future<void> init() async {
    await sceneRepository.loadAll();
    world = SaveManager.loadWorld();
    final savedRun = SaveManager.loadRun();
    if (savedRun != null) {
      character = savedRun;
      _loadCurrentScene();
    }
    // else: leave character null on purpose - _AppRoot will route to
    // CharacterCreationScreen via needsCharacterCreation above.
    isLoaded = true;
    notifyListeners();
  }

  void _loadCurrentScene() {
    final activeCharacter = character;
    if (activeCharacter == null) return;
    currentScene = sceneRepository.getScene(activeCharacter.currentSceneId);
  }

  ConditionEvaluator get _evaluator {
    final activeCharacter = character;
    if (activeCharacter == null) {
      throw StateError(
        'ConditionEvaluator requested with no active character - this '
        'means a screen tried to read scene content before character '
        'creation finished. Check needsCharacterCreation first.',
      );
    }
    return ConditionEvaluator(character: activeCharacter, world: world);
  }

  /// Returns the narrative text to display for the current scene,
  /// substituting in a flag- or origin-gated variant if one matches.
  String get currentNarrative {
    final scene = currentScene;
    if (scene == null) return '';
    for (final entry in scene.narrativeVariants.entries) {
      if (_evaluator.evaluate(entry.key)) {
        return entry.value;
      }
    }
    return scene.narrative;
  }

  /// Choices filtered down to only the ones whose condition currently
  /// evaluates true (this is where origin-gated choices, like a Royal
  /// Heir being recognized by guards, get hidden from everyone else).
  List<SceneChoice> get availableChoices {
    final scene = currentScene;
    if (scene == null) return const [];
    return scene.choices
        .where((c) => _evaluator.evaluate(c.conditionExpression))
        .toList();
  }

  /// Starts a brand-new run for a freshly created (or freshly
  /// resurrected-as-someone-else) character. Used both for the very
  /// first character in a fresh install AND after a death, once the
  /// player has picked a name + Archetype on CharacterCreationScreen.
  Future<void> beginRun({
    required String name,
    required Archetype archetype,
  }) async {
    isDead = false;
    deathCause = null;
    lastCheckResult = null;
    character = CharacterState.fromArchetype(name: name, archetype: archetype);
    _loadCurrentScene();
    await SaveManager.saveRun(character!);
    notifyListeners();
  }

  Future<void> selectChoice(SceneChoice choice) async {
    final activeCharacter = character;
    if (activeCharacter == null) return; // defensive - UI shouldn't allow this
    lastCheckResult = null;

    // Apply immediate effects (world flags, run history entries) first.
    choice.effects.forEach((key, value) {
      if (key.startsWith('world_flags.')) {
        final flagKey = key.substring('world_flags.'.length);
        LegacyEngine.applyFlagEffect(world, flagKey, value);
      } else if (key == 'run_history') {
        activeCharacter.runHistory.add(value as String);
      }
    });

    if (choice.isFatal) {
      await _handleDeath(choice.fatalCause ?? 'Unknown cause');
      return;
    }

    String nextSceneId;
    if (choice.hasStatCheck) {
      final modifier =
          activeCharacter.attributes[choice.requiredAttribute!] ?? 0;
      final result = diceRoller.check(
        modifier: modifier,
        difficultyClass: choice.difficultyClass!,
      );
      lastCheckResult = result;
      nextSceneId = result.success
          ? choice.outcomeSuccessNode
          : (choice.outcomeFailNode ?? choice.outcomeSuccessNode);
    } else {
      nextSceneId = choice.outcomeSuccessNode;
    }

    activeCharacter.currentSceneId = nextSceneId;
    _loadCurrentScene();
    await SaveManager.saveRun(activeCharacter);

    if (activeCharacter.isDead) {
      await _handleDeath(
        activeCharacter.age >= activeCharacter.maxAge
            ? 'Old age'
            : 'Wounds sustained',
      );
      return;
    }

    notifyListeners();
  }

  Future<void> _handleDeath(String cause) async {
    final activeCharacter = character;
    if (activeCharacter == null) return;
    isDead = true;
    deathCause = cause;
    world = await LegacyEngine.recordDeath(
      character: activeCharacter,
      world: world,
      causeOfDeath: cause,
    );
    // OPTIMIZATION/CLARITY NOTE: clearing character here (rather than in
    // beginRun) means "isDead == true" and "character == null" become
    // true at the same moment - DeathScreen can safely read the character
    // that just died from LegacyEngine's result (world.mostRecentHero)
    // instead of holding a stale CharacterState reference around.
    character = null;
    currentScene = null;
    notifyListeners();
  }

  /// Called from DeathScreen once the player has read the death recap
  /// and is ready to move on. Flips isDead off so needsCharacterCreation
  /// becomes true and _AppRoot routes to CharacterCreationScreen.
  void acknowledgeDeath() {
    isDead = false;
    deathCause = null;
    notifyListeners();
  }
}
