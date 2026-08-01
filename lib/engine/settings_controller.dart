import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'save_manager.dart';

/// PROBLEM: adding a Settings screen meant deciding where preferences
/// live. Reusing GameController would have mixed "story state" (which
/// scene you're on, who's dead) with "device preferences" (text size,
/// theme) in one class - two very different lifecycles (settings should
/// survive resetWorld(); story state should not). SOLUTION: a separate
/// SettingsController with its own save slot, so wiping your save data
/// (Settings > Reset World) never touches your text-size/theme choice.
class SettingsController extends ChangeNotifier {
  AppSettings settings = AppSettings();

  Future<void> load() async {
    settings = SaveManager.loadSettings();
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    settings.textScale = value;
    await SaveManager.saveSettings(settings);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    settings.darkMode = value;
    await SaveManager.saveSettings(settings);
    notifyListeners();
  }

  Future<void> setShowRollBanner(bool value) async {
    settings.showRollBanner = value;
    await SaveManager.saveSettings(settings);
    notifyListeners();
  }
}
