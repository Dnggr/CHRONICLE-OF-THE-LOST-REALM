import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/character_state.dart';
import '../models/world_history.dart';

/// Handles all local persistence. Two SEPARATE boxes on purpose:
///
/// - `run_box`     -> the active CharacterState. Overwritten on save,
///                    CLEARED when a new run starts after death.
/// - `world_box`   -> the permanent WorldHistory. Only ever appended to,
///                    never cleared - this is the whole point of the
///                    legacy system.
class SaveManager {
  static const _runBoxName = 'run_box';
  static const _worldBoxName = 'world_box';
  static const _runKey = 'current_run';
  static const _worldKey = 'world_history';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_runBoxName);
    await Hive.openBox<String>(_worldBoxName);
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
}
