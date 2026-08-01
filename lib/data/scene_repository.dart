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
