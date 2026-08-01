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

/// The top-level screen the app is showing. Added this session alongside
/// MainMenuScreen/SettingsScreen/HistoryScreen.
///
/// PROBLEM: before this, routing was a single boolean
/// (`needsCharacterCreation`) with exactly two destinations
/// (CharacterCreationScreen or SceneScreen) - fine for two screens, but
/// adding a proper main menu meant "no character yet" could no longer
/// mean just one thing (it now also covers "sitting at the main menu
/// with a character in progress, deciding whether to hit Continue").
/// SOLUTION: an explicit enum with one entry per top-level destination.
/// History and Settings are NOT in this enum on purpose - they're
/// pushed via Navigator.push as "excursions" you back out of, rather
/// than swapped-in root screens, because you always return to exactly
/// where you were (menu or mid-game) when you close them.
enum AppScreen { mainMenu, characterCreation, playing }

/// The single source of truth the UI listens to. Owns the active
/// CharacterState, the permanent WorldHistory, and the scene graph.
///
/// CHANGE LOG (see /DEVLOG.md for the full narrative of each session):
/// - [character] used to be `late` and auto-filled with a generic
///   "Wanderer" the instant the app opened. Now nullable - null means
///   "no run in progress," full stop, regardless of which screen is
///   showing.
class GameController extends ChangeNotifier {
  final SceneRepository sceneRepository;
  final DiceRoller diceRoller;

  CharacterState? character;
  late WorldHistory world;
  SceneNode? currentScene;

  AppScreen screen = AppScreen.mainMenu;

  /// True once init() has finished loading scenes + save data.
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

  /// True if there's a run to resume - drives whether MainMenuScreen
  /// shows a "Continue" button at all.
  bool get hasActiveRun => character != null;

  Future<void> init() async {
    await sceneRepository.loadAll();
    world = SaveManager.loadWorld();
    final savedRun = SaveManager.loadRun();
    if (savedRun != null) {
      character = savedRun;
      _loadCurrentScene();
    }
    // NOTE: even with a saved run present, we deliberately start at
    // AppScreen.mainMenu (the enum's default) rather than jumping
    // straight into SceneScreen - the player should always land on the
    // main menu first and choose Continue, same as most games.
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
        'ConditionEvaluator requested with no active character - a '
        'screen tried to read scene content while screen != playing.',
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

  // ---- Top-level navigation ----
  //
  // These four methods are the ONLY way `screen` should change. Keeping
  // every transition here (instead of screens setting `screen` directly)
  // means every entry/exit point for gameplay is in one place - useful
  // the next time a bug report says "how did the player end up here."

  void goToMainMenu() {
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  void goToCharacterCreation() {
    screen = AppScreen.characterCreation;
    notifyListeners();
  }

  /// Called from MainMenuScreen's "Continue" button. No-ops if there's
  /// nothing to resume (button should be hidden in that case anyway -
  /// this is a defensive backstop, not the primary guard).
  void resumeGame() {
    if (character == null) return;
    screen = AppScreen.playing;
    notifyListeners();
  }

  /// Starts a brand-new run for a freshly created character. Used both
  /// for the very first character in a fresh install AND after a death,
  /// once the player has picked a name + Archetype.
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
    screen = AppScreen.playing;
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
    character = null;
    currentScene = null;
    notifyListeners();
  }

  /// Called from DeathScreen once the player has read the death recap.
  ///
  /// PROBLEM: this used to send the player straight back into
  /// CharacterCreationScreen. Once a real main menu existed, that felt
  /// wrong - after a death, the player should be able to check History
  /// (see their fallen hero's final Chronicle entry) or Settings before
  /// deciding to start again. SOLUTION: route to the main menu instead;
  /// "New Game" from there goes to character creation same as always.
  void acknowledgeDeath() {
    isDead = false;
    deathCause = null;
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  /// Settings > Reset World. Wipes BOTH the active run and the permanent
  /// Chronicle - this is the only place in the app allowed to touch
  /// world_box's contents. Always gate the call site behind a
  /// confirmation dialog (see SettingsScreen) - there is no undo.
  Future<void> resetWorld() async {
    await SaveManager.clearRun();
    await SaveManager.clearWorld();
    character = null;
    currentScene = null;
    world = WorldHistory();
    isDead = false;
    deathCause = null;
    screen = AppScreen.mainMenu;
    notifyListeners();
  }
}
