import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/character_state.dart';
import '../models/world_history.dart';

/// Handles all local persistence. THREE separate boxes on purpose:
///
/// - `run_box`      -> the active CharacterState. Overwritten on save,
///                     CLEARED when a new run starts after death.
/// - `world_box`    -> the permanent WorldHistory. Only ever appended to
///                     during normal play - only clearable via an
///                     explicit Settings > Reset World action.
/// - `settings_box` -> AppSettings (text size, theme, etc). PROBLEM this
///                     separation solves: the Settings screen's "Reset
///                     World" button needs to wipe `world_box` without
///                     touching the player's text-size/theme choice -
///                     one box per box means one clear() call can never
///                     accidentally take out data it shouldn't.
class SaveManager {
  static const _runBoxName = 'run_box';
  static const _worldBoxName = 'world_box';
  static const _settingsBoxName = 'settings_box';
  static const _runKey = 'current_run';
  static const _worldKey = 'world_history';
  static const _settingsKey = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_runBoxName);
    await Hive.openBox<String>(_worldBoxName);
    await Hive.openBox<String>(_settingsBoxName);
  }

  // ---- Current run ----

  static Future<void> saveRun(CharacterState state) async {
    final box = Hive.box<String>(_runBoxName);
    await box.put(_runKey, jsonEncode(state.toJson()));
  }

  static CharacterState? loadRun() {
    final box = Hive.box<String>(_runBoxName);
    final raw = box.get(_runKey);
    if (raw == null) return null;
    return CharacterState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clearRun() async {
    final box = Hive.box<String>(_runBoxName);
    await box.delete(_runKey);
  }

  // ---- World history (permanent legacy save) ----

  static Future<void> saveWorld(WorldHistory world) async {
    final box = Hive.box<String>(_worldBoxName);
    await box.put(_worldKey, jsonEncode(world.toJson()));
  }

  static WorldHistory loadWorld() {
    final box = Hive.box<String>(_worldBoxName);
    final raw = box.get(_worldKey);
    if (raw == null) return WorldHistory();
    return WorldHistory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Only ever called from the Settings screen's explicit "Reset World"
  /// action (with a confirmation dialog in front of it) - this is the
  /// one place the permanent legacy save is allowed to be wiped.
  static Future<void> clearWorld() async {
    final box = Hive.box<String>(_worldBoxName);
    await box.delete(_worldKey);
  }

  // ---- Settings ----

  static Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box<String>(_settingsBoxName);
    await box.put(_settingsKey, jsonEncode(settings.toJson()));
  }

  static AppSettings loadSettings() {
    final box = Hive.box<String>(_settingsBoxName);
    final raw = box.get(_settingsKey);
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
