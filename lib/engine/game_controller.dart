import 'package:flutter/foundation.dart';

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
class GameController extends ChangeNotifier {
  final SceneRepository sceneRepository;
  final DiceRoller diceRoller;

  late CharacterState character;
  late WorldHistory world;
  SceneNode? currentScene;

  /// Set right after a stat check so the UI can show "Roll: 14 + 2 = 16
  /// vs DC 12 - Success!" before the player taps to continue.
  StatCheckResult? lastCheckResult;

  bool isDead = false;
  String? deathCause;

  GameController({
    required this.sceneRepository,
    DiceRoller? diceRoller,
  }) : diceRoller = diceRoller ?? DiceRoller();

  Future<void> init() async {
    await sceneRepository.loadAll();
    world = SaveManager.loadWorld();
    final savedRun = SaveManager.loadRun();
    if (savedRun != null) {
      character = savedRun;
    } else {
      character = LegacyEngine.startNewRun(name: 'Wanderer');
    }
    _loadCurrentScene();
    notifyListeners();
  }

  void _loadCurrentScene() {
    currentScene = sceneRepository.getScene(character.currentSceneId);
  }

  ConditionEvaluator get _evaluator =>
      ConditionEvaluator(character: character, world: world);

  /// Returns the narrative text to display for the current scene,
  /// substituting in a flag-gated variant if one matches.
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
  /// evaluates true.
  List<SceneChoice> get availableChoices {
    final scene = currentScene;
    if (scene == null) return const [];
    return scene.choices
        .where((c) => _evaluator.evaluate(c.conditionExpression))
        .toList();
  }

  Future<void> selectChoice(SceneChoice choice) async {
    lastCheckResult = null;

    // Apply immediate effects (world flags, run history entries) first.
    choice.effects.forEach((key, value) {
      if (key.startsWith('world_flags.')) {
        final flagKey = key.substring('world_flags.'.length);
        LegacyEngine.applyFlagEffect(world, flagKey, value);
      } else if (key == 'run_history') {
        character.runHistory.add(value as String);
      }
    });

    if (choice.isFatal) {
      await _handleDeath(choice.fatalCause ?? 'Unknown cause');
      return;
    }

    String nextSceneId;
    if (choice.hasStatCheck) {
      final modifier = character.attributes[choice.requiredAttribute!] ?? 0;
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

    character.currentSceneId = nextSceneId;
    _loadCurrentScene();
    await SaveManager.saveRun(character);

    if (character.isDead) {
      await _handleDeath(
        character.age >= character.maxAge ? 'Old age' : 'Wounds sustained',
      );
      return;
    }

    notifyListeners();
  }

  Future<void> _handleDeath(String cause) async {
    isDead = true;
    deathCause = cause;
    world = await LegacyEngine.recordDeath(
      character: character,
      world: world,
      causeOfDeath: cause,
    );
    notifyListeners();
  }

  Future<void> startNewRunAfterDeath({required String name}) async {
    isDead = false;
    deathCause = null;
    lastCheckResult = null;
    character = LegacyEngine.startNewRun(name: name);
    _loadCurrentScene();
    await SaveManager.saveRun(character);
    notifyListeners();
  }
}
