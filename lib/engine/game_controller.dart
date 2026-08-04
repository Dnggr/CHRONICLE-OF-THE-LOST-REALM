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

  /// True from the first tap until the choice has been saved and the next
  /// scene is ready. It prevents two fast taps from applying the same
  /// effects twice or navigating two branches at once.
  ///
  /// PROBLEM (UI pass, this session): SceneScreen now also uses this
  /// flag to decide when to show a brief "you picked this one" confirm
  /// state on the tapped button before the block collapses into the
  /// recap line - see ChoiceButton and SceneScreen for the UI half of
  /// this. That only works if [SceneLogEntry.chosenLabel] is already
  /// set the FIRST time the UI rebuilds after a tap, and if that
  /// confirm state stays on screen long enough to actually read as a
  /// beat rather than a flicker. Both of those are handled in
  /// [selectChoice] below.
  bool isSelectingChoice = false;

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
  ///
  /// NOTE: the UI no longer reads this directly to render buttons (see
  /// SceneLogEntry.choices for why) - it's kept as the engine-side
  /// source of truth for validating a tap in [selectChoice] below, and
  /// as what gets snapshotted into each new log entry the moment it's
  /// created.
  List<SceneChoice> get availableChoices {
    final scene = currentScene;
    if (scene == null) return const [];
    return scene.choices
        .where((c) => _evaluator.evaluate(c.conditionExpression))
        .toList();
  }

  /// Appends [currentScene] to the scroll as a fresh, not-yet-answered
  /// entry. Must be called AFTER `character` and `currentScene` are both
  /// set to their new values (relies on `_resolvedCurrentNarrative` and
  /// `availableChoices`).
  void _appendCurrentSceneToLog() {
    final scene = currentScene;
    if (scene == null) return;
    sceneLog.add(SceneLogEntry(
      sceneId: scene.sceneId,
      narrative: _resolvedCurrentNarrative,
      illustrationId: scene.illustrationId,
      // Frozen the instant this entry is created - see the PROBLEM/
      // SOLUTION note on SceneLogEntry.choices for why this can't just
      // be read live off `availableChoices` later.
      choices: availableChoices,
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

  /// Minimum time the "you picked this one" confirm state (see
  /// ChoiceButton.isChosen/isDimmed) stays on screen before the block
  /// collapses into the recap line - regardless of how fast the actual
  /// save/scene-load work below finishes. Without this, a fast device
  /// (or an already-warm Hive box) could resolve the whole thing in a
  /// handful of milliseconds, which reads as a flicker instead of a
  /// deliberate beat. Race it against the real work (see `Future.wait`
  /// below) so a SLOW device never waits any longer than it already
  /// would have.
  static const _minConfirmFeedback = Duration(milliseconds: 260);

  Future<void> selectChoice(SceneChoice choice) async {
    final activeCharacter = character;
    if (activeCharacter == null || isSelectingChoice) return;
    // SceneScreen only passes visible choices, but this is the engine
    // boundary: callers must not be able to invoke a hidden/stale choice
    // directly after state has changed.
    if (!availableChoices.contains(choice)) return;

    // A JSON author can forget a `gold >= N` condition. Keep the story
    // data friendly, but enforce the economy here as a final safeguard so
    // an unaffordable negative delta can never create negative gold.
    final goldDelta = choice.effects['gold'];
    if (goldDelta is num && activeCharacter.gold + goldDelta.toInt() < 0) {
      return;
    }

    // PROBLEM (UI pass, this session): this used to be set AFTER the
    // first notifyListeners() below, so the very first frame SceneScreen
    // drew after a tap had no idea which of possibly several buttons
    // had just been pressed - every button simply went disabled at
    // once. SOLUTION: write chosenLabel to the log entry FIRST, so the
    // first rebuild already knows the answer and can highlight that
    // exact button instead of graying out the whole list uniformly.
    if (sceneLog.isNotEmpty) {
      sceneLog.last.chosenLabel = choice.label;
    }

    // PROBLEM: ChoiceButton remained tappable while async save/scene work
    // was underway. A rapid double tap could apply gold/reputation effects
    // twice or race two scene transitions. SOLUTION: one controller-owned
    // interaction lock protects every choice, independent of UI timing.
    isSelectingChoice = true;
    notifyListeners();

    final minFeedback = Future<void>.delayed(_minConfirmFeedback);

    try {
      lastCheckResult = null;

      // Apply immediate effects (world flags, run history entries) first.
      // PROBLEM: SceneChoice.effects previously only understood
      // "world_flags.<key>" and "run_history" - the Story & Systems
      // Bible's Honor System needed a way for a single choice to also
      // move a reputation track or a specific NPC's trust. SOLUTION:
      // three more key prefixes, all still going through this one
      // effects-application block so there's still exactly one place
      // choice consequences get applied, not several.
      choice.effects.forEach((key, value) {
        if (key.startsWith('world_flags.')) {
          final flagKey = key.substring('world_flags.'.length);
          LegacyEngine.applyFlagEffect(world, flagKey, value);
        } else if (key == 'run_history') {
          activeCharacter.runHistory.add(value as String);
        } else if (key.startsWith('reputation.')) {
          // value is a DELTA (e.g. -2, +5), not an absolute value - so
          // repeated choices accumulate naturally instead of overwriting.
          final track = key.substring('reputation.'.length);
          final delta = (value as num).toInt();
          activeCharacter.reputation[track] =
              (activeCharacter.reputation[track] ?? 0) + delta;
        } else if (key.startsWith('npc.') && key.endsWith('.trust')) {
          final npcId = key.substring(4, key.length - '.trust'.length);
          final delta = (value as num).toInt();
          activeCharacter.npcTrust[npcId] =
              (activeCharacter.npcTrust[npcId] ?? 0) + delta;
        } else if (key.startsWith('npc.') && key.endsWith('.status')) {
          final npcId = key.substring(4, key.length - '.status'.length);
          activeCharacter.npcStatus[npcId] = value as String;
        } else if (key == 'gold') {
          // PROBLEM: several Harvest Failure choices promise a gold cost
          // in their label ("-15 Gold") but nothing applied it - effects
          // only understood world_flags/run_history/reputation/npc keys.
          // SOLUTION: a plain numeric delta on character.gold, same
          // pattern as every other numeric effect here.
          final delta = (value as num).toInt();
          activeCharacter.gold += delta;
        } else if (key == 'inventory_add') {
          // PROBLEM: Old Hendrik's aftermath scenes hand the player a
          // physical keepsake (his toolkit if he lived, his whetstone if
          // he didn't) - narratively real, but nothing applied it to the
          // save data, so "inheriting" his tools was prose with no
          // mechanical weight behind it.
          // SOLUTION: appends a single item name to inventory, same
          // list Archetype/EquipmentKit starting gear already populates.
          activeCharacter.inventory.add(value as String);
        }
      });

      if (choice.isFatal) {
        await minFeedback;
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

      if (sceneLog.isNotEmpty) {
        sceneLog.last.chosenAftermath = lastCheckResult?.success == false
            ? (choice.aftermathFailure ?? choice.aftermath ?? _defaultAftermath)
            : (choice.aftermath ?? _defaultAftermath);
      }

      activeCharacter.currentSceneId = nextSceneId;
      _loadCurrentScene();

      // Real work + the minimum confirm-feedback beat run concurrently -
      // whichever takes longer decides when we move on. A slow device
      // never waits extra; a fast one still shows the confirm state
      // long enough to register.
      await Future.wait([
        SaveManager.saveRun(activeCharacter),
        minFeedback,
      ]);

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
      // screen rather than appending to it. This is also the moment the
      // just-answered entry stops being "latest", which is what tells
      // SceneScreen to collapse its confirm state into the recap line -
      // see `_LogEntryView`'s `showingRecap` in scene_screen.dart.
      _appendCurrentSceneToLog();
      notifyListeners();
    } finally {
      isSelectingChoice = false;
      notifyListeners();
    }
  }

  static const _defaultAftermath =
      'The choice settles into the room. Someone hears it, someone reacts, '
      'and the road carries the consequence forward.';

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
