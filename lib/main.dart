import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/scene_repository.dart';
import 'engine/game_controller.dart';
import 'engine/save_manager.dart';
import 'engine/settings_controller.dart';
import 'ui/screens/character_creation_screen.dart';
import 'ui/screens/main_menu_screen.dart';
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
    // PROBLEM: adding Settings meant the app needed a second
    // ChangeNotifier (SettingsController) alongside GameController, and
    // both needed to be visible from every screen (MainMenu, History,
    // Settings, and the in-game screens all read at least one of them).
    // SOLUTION: MultiProvider at the root, same pattern as before, just
    // with two providers instead of one - no screen needs to know which
    // provider tree wraps which other provider.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameController>(
          create: (_) => GameController(
            sceneRepository: SceneRepository(),
          )..init(),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController()..load(),
        ),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Reads SettingsController to decide theme + global text scale, so
/// changing either in SettingsScreen takes effect immediately across
/// the whole app without any screen needing to re-read settings itself.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;

    return MaterialApp(
      title: 'Chronicle of the Lost Realm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: settings.darkMode ? Brightness.dark : Brightness.light,
      ),
      // Global text-size setting: scales every Text widget in the app
      // via MediaQuery rather than threading a scale factor through
      // every widget individually.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          child: child!,
        );
      },
      home: const _AppRoot(),
    );
  }
}

/// Top-level router.
///
/// CHANGE LOG: this used to branch straight to CharacterCreationScreen
/// or SceneScreen. PROBLEM: there was no home base, and no way to reach
/// History/Settings without already being mid-game. SOLUTION: MainMenu
/// is now the default AppScreen.mainMenu destination, and
/// History/Settings are reached from there (or from SceneScreen's
/// bottom nav) via Navigator.push, layered on top of whichever root
/// screen this switch statement picked.
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
        switch (controller.screen) {
          case AppScreen.mainMenu:
            return const MainMenuScreen();
          case AppScreen.characterCreation:
            return const CharacterCreationScreen();
          case AppScreen.playing:
            return const SceneScreen();
        }
      },
    );
  }
}
