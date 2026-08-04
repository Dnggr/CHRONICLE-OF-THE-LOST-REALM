import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/scene_node.dart';

/// Loads scene JSON files bundled under assets/scenes/ and gives fast
/// lookup by sceneId. Add new files to the [_sceneFiles] list AND to
/// pubspec.yaml's assets section when you add new chapters.
class SceneRepository {
  final Map<String, SceneNode> _scenesById = {};

  static const List<String> _sceneFiles = [
    'assets/scenes/prologue.json',
    // PROBLEM: origin intros were a single scene each, far short of the
    // rule-10 density floor (15-20 real choice points before the first
    // common event). SOLUTION: Wanderer is the first origin rebuilt to
    // that standard - its own file, loaded alongside prologue.json, with
    // prologue_start routing straight into it instead of the old
    // single-scene prologue_wanderer_intro (removed). The other six
    // origins still use their single-scene intros in prologue.json and
    // are next in line for the same treatment - see
    // npc_dialogue_and_routes.txt's CURRENT PLAYABLE SEQUENCE note.
    'assets/scenes/wanderer_intro.json',
    'assets/scenes/wanderer_event_corwins_sister.json',
    'assets/scenes/royal_heir_route.json',
    'assets/scenes/royal_aldous_route.json',
    'assets/scenes/mira_talbot_route.json',
    'assets/scenes/chapter1_harvest.json',
    // PROBLEM: Chapter 1 previously ended by returning to prologue_start,
    // making the Harvest Failure a loop instead of a world event with a
    // consequence. SOLUTION: Event 1 lives in its own scene graph and is
    // loaded beside the existing chapters, so Chapter 1 can lead into the
    // Salt Road rebellion without hard-coding narrative flow in the UI.
    'assets/scenes/event1_rebellion.json',
    'assets/scenes/route_interludes.json',
    'assets/scenes/salt_road_culture_route.json',
    // The authored early-campaign spine. Event 3's file is loaded for
    // validation, but its only entry choice is gated by sun_temple_destroyed.
    'assets/scenes/event2_northern_war.json',
    'assets/scenes/event3_sun_temple_schism.json',
    'assets/scenes/event4_hollow_plague.json',
    'assets/scenes/event5_succession_crisis.json',
    'assets/scenes/event6_salt_sea_invasion.json',
    'assets/scenes/event7_dark_legion.json',
    'assets/scenes/event8_demon_lord.json',
  ];

  Future<void> loadAll() async {
    for (final path in _sceneFiles) {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);

      // Each file is a JSON array of scene node objects.
      final List<dynamic> list = decoded as List<dynamic>;
      for (final entry in list) {
        final node = SceneNode.fromJson(entry as Map<String, dynamic>);
        _scenesById[node.sceneId] = node;
      }
    }
  }

  SceneNode getScene(String sceneId) {
    final node = _scenesById[sceneId];
    if (node == null) {
      throw StateError(
        'No scene found with id "$sceneId". Check assets/scenes/*.json '
        'for a typo, and confirm the file is listed in pubspec.yaml assets.',
      );
    }
    return node;
  }

  bool hasScene(String sceneId) => _scenesById.containsKey(sceneId);
}