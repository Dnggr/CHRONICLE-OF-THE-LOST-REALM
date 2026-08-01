import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/scene_repository.dart';
import 'engine/game_controller.dart';
import 'engine/save_manager.dart';
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

/// Waits for GameController.init() to finish loading scenes + save data
/// before showing the reading screen.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        if (controller.currentScene == null && !controller.isDead) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const SceneScreen();
      },
    );
  }
}
