import 'package:flutter/foundation.dart';

import '../data/archetypes.dart';
import '../data/backgrounds.dart';
import '../data/equipment_kits.dart';
import '../data/scene_repository.dart';
import '../data/traits.dart';
import '../models/character_state.dart';
import '../models/scene_log_entry.dart';
import '../models/scene_node.dart';
import '../models/world_history.dart';
import 'condition_evaluator.dart';
import 'dice_roller.dart';
import 'legacy_engine.dart';
import 'save_manager.dart';

/// The top-level screen the app is showing. Added alongside
/// MainMenuScreen/SettingsScreen/HistoryScreen (see DEVLOG.md Session 3).
enum AppScreen { mainMenu, characterCreation, playing }

/// The single source of truth the UI listens to. Owns the active
/// CharacterState, the permanent WorldHistory, the scene graph, AND (as
/// of Session 4) the scrolling reading log - see SceneLogEntry's doc
/// comment in models/scene_log_entry.dart for why the log exists and
/// what it deliberately does NOT persist across app restarts.
class GameController extends ChangeNotifier {
  final SceneRepository sceneRepository;
  final DiceRoller diceRoller;

  CharacterState? character;
  late WorldHistory world;
  SceneNode? currentScene;

  /// The scrolling transcript for the CURRENT play session. The last
  /// entry (chosenLabel == null) is always the one whose sceneId matches
  /// [currentScene] and whose choices are shown as live buttons - see
  /// `availableChoices` below. Every earlier entry is a frozen,
  /// already-answered part of the scroll.
  List<SceneLogEntry> sceneLog = [];

  AppScreen screen = AppScreen.mainMenu;

  /// True once init() has finished loading scenes + save data.
  bool isLoaded = false;

  /// Set right after a stat check so the UI can show "Roll: 14 + 2 = 16
  /// vs DC 12 - Success!" attached to the newest log entry.
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
      // NOTE: sceneLog is intentionally left empty here, not populated -
      // it gets its first (and only, until a choice is made) entry
      // lazily in resumeGame(), the moment the player actually enters
      // SceneScreen. Populating it here would mean rebuilding it again
      // in resumeGame() anyway once `screen` flips to playing.
    }
    // Even with a saved run present, we deliberately start at
    // AppScreen.mainMenu rather than jumping straight into SceneScreen -
    // the player should always land on the main menu first.
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

  /// Resolves narrativeVariants against the CURRENT character/world
  /// state and returns the text to show. Only called at the moment a
  /// scene is entered (see _appendCurrentSceneToLog) - the result is
  /// then baked into a SceneLogEntry and never re-evaluated, so a scene
  /// you already read doesn't silently reword itself if a later choice
  /// changes a flag it depended on.
  String get _resolvedCurrentNarrative {
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
  /// Always describes [currentScene] - i.e. the LATEST sceneLog entry.
  List<SceneChoice> get availableChoices {
    final scene = currentScene;
    if (scene == null) return const [];
    return scene.choices
        .where((c) => _evaluator.evaluate(c.conditionExpression))
        .toList();
  }

  /// Appends [currentScene] to the scroll as a fresh, not-yet-answered
  /// entry. Must be called AFTER `character` and `currentScene` are both
  /// set to their new values (relies on `_resolvedCurrentNarrative`).
  void _appendCurrentSceneToLog() {
    final scene = currentScene;
    if (scene == null) return;
    sceneLog.add(SceneLogEntry(
      sceneId: scene.sceneId,
      narrative: _resolvedCurrentNarrative,
      illustrationId: scene.illustrationId,
    ));
  }

  // ---- Top-level navigation ----
  //
  // These are the ONLY methods that should change `screen`. Keeping
  // every transition here means every entry/exit point for gameplay is
  // in one place.

  void goToMainMenu() {
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  void goToCharacterCreation() {
    screen = AppScreen.characterCreation;
    notifyListeners();
  }

  /// Called from MainMenuScreen's "Continue" button, or from
  /// SceneScreen's Home->back round trip.
  ///
  /// PROBLEM: after switching to the scrolling log (Session 4), simply
  /// flipping `screen` back to playing wasn't enough - if sceneLog was
  /// still empty (fresh app launch, saved run just loaded in init()),
  /// SceneScreen would have nothing to render. SOLUTION: lazily seed the
  /// log with the current scene ONLY if it's empty - this also means
  /// going Home mid-run and hitting Continue again keeps your scroll
  /// history intact (sceneLog is untouched, just not empty).
  void resumeGame() {
    if (character == null) return;
    if (sceneLog.isEmpty) {
      _appendCurrentSceneToLog();
    }
    screen = AppScreen.playing;
    notifyListeners();
  }

  /// Starts a brand-new run for a freshly created character. Used both
  /// for the very first character in a fresh install AND after a death,
  /// once the player has gone through every step of CharacterCreationScreen
  /// (name, gender, portrait, archetype, background, trait, stat
  /// distribution, starting equipment).
  Future<void> beginRun({
    required String name,
    required String gender,
    required String portraitId,
    required Archetype archetype,
    required Background background,
    required Trait trait,
    required EquipmentKit equipmentKit,
    required Map<String, int> baseAttributes,
  }) async {
    isDead = false;
    deathCause = null;
    lastCheckResult = null;
    character = CharacterState.fromCreationData(
      name: name,
      gender: gender,
      portraitId: portraitId,
      archetype: archetype,
      background: background,
      trait: trait,
      equipmentKit: equipmentKit,
      baseAttributes: baseAttributes,
    );
    _loadCurrentScene();
    sceneLog = []; // fresh scroll for a fresh life
    _appendCurrentSceneToLog();
    await SaveManager.saveRun(character!);
    screen = AppScreen.playing;
    notifyListeners();
  }

  Future<void> selectChoice(SceneChoice choice) async {
    final activeCharacter = character;
    if (activeCharacter == null) return; // defensive - UI shouldn't allow this
    lastCheckResult = null;

    // Freeze the entry the player just acted on with the label they
    // picked, BEFORE we know whether this leads to a stat check, a
    // fatal outcome, or a normal transition - the log should record
    // what was chosen regardless of what happens next.
    if (sceneLog.isNotEmpty) {
      sceneLog.last.chosenLabel = choice.label;
    }

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

    // Only append the next block to the scroll once we know the
    // character survived the transition - a fatal outcome hands off to
    // DeathScreen instead (see _handleDeath), which replaces the whole
    // screen rather than appending to it.
    _appendCurrentSceneToLog();
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
    sceneLog = [];
    notifyListeners();
  }

  /// Called from DeathScreen once the player has read the death recap.
  /// Routes to the main menu rather than straight into character
  /// creation, so History/Settings are reachable before starting again.
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
    sceneLog = [];
    world = WorldHistory();
    isDead = false;
    deathCause = null;
    screen = AppScreen.mainMenu;
    notifyListeners();
  }
}
