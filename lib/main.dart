import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/scene_repository.dart';
import 'engine/game_controller.dart';
import 'engine/save_manager.dart';
import 'ui/screens/character_creation_screen.dart';
import 'ui/screens/scene_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveManager.init();
  runApp(const LostRealmApp());
}

class LostRealmApp extends StatelessWidget {
  const LostRealmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameController>(
      create: (_) => GameController(
        sceneRepository: SceneRepository(),
      )..init(),
      child: MaterialApp(
        title: 'Chronicle of the Lost Realm',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.amber,
          brightness: Brightness.light,
        ),
        home: const _AppRoot(),
      ),
    );
  }
}

/// Top-level router. PROBLEM this replaced: the old version only checked
/// "is there a scene loaded" to decide between a spinner and SceneScreen
/// - there was no state for "loaded, but the player hasn't created a
/// character yet." SOLUTION: three explicit states, checked in order:
///   1. still loading save data / scene JSON  -> spinner
///   2. loaded, but no character exists yet   -> CharacterCreationScreen
///      (covers BOTH first-ever launch and "just died, pick your next
///      hero" - see GameController.acknowledgeDeath())
///   3. otherwise                              -> SceneScreen, which
///      internally branches to DeathScreen if isDead is somehow true
///      here (defensive; shouldn't happen given #2, but cheap to keep).
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        if (!controller.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.needsCharacterCreation) {
          return const CharacterCreationScreen();
        }
        return const SceneScreen();
      },
    );
  }
}
