/// A single choice available inside a scene.
///
/// [conditionExpression] gates whether the choice is even shown, e.g.
/// "flags.sun_temple_destroyed == true" or "inventory.contains('poultice')".
/// Leave null for a choice that is always available.
///
/// [requiredAttribute] + [difficultyClass] together define an optional
/// 1d20 + attribute-modifier stat check. If [requiredAttribute] is null,
/// the choice always resolves to [outcomeSuccessNode] with no roll.
class SceneChoice {
  final String id;
  final String label;
  final String? conditionExpression;
  final String? requiredAttribute;
  final int? difficultyClass;
  final String outcomeSuccessNode;
  final String? outcomeFailNode;

  /// Set of "world_flags" or "run_history" entries to apply when this
  /// choice is taken, regardless of success/fail. Example:
  /// { "world_flags.sun_temple_destroyed": true }
  final Map<String, dynamic> effects;

  /// If true, taking this choice ends the current run in death.
  final bool isFatal;
  final String? fatalCause;

  const SceneChoice({
    required this.id,
    required this.label,
    this.conditionExpression,
    this.requiredAttribute,
    this.difficultyClass,
    required this.outcomeSuccessNode,
    this.outcomeFailNode,
    this.effects = const {},
    this.isFatal = false,
    this.fatalCause,
  });

  factory SceneChoice.fromJson(Map<String, dynamic> json) {
    return SceneChoice(
      id: json['id'] as String,
      label: json['label'] as String,
      conditionExpression: json['condition'] as String?,
      requiredAttribute: json['requiredAttribute'] as String?,
      difficultyClass: json['difficultyClass'] as int?,
      outcomeSuccessNode: json['outcomeSuccessNode'] as String,
      outcomeFailNode: json['outcomeFailNode'] as String?,
      effects: (json['effects'] as Map?)?.cast<String, dynamic>() ?? const {},
      isFatal: json['isFatal'] as bool? ?? false,
      fatalCause: json['fatalCause'] as String?,
    );
  }

  bool get hasStatCheck => requiredAttribute != null && difficultyClass != null;
}

/// A single node in the story graph. Loaded from assets/scenes/*.json.
///
/// [narrativeVariants] lets one scene id show different prose depending on
/// which world flag is currently true, without needing a separate node.
/// Keys are condition expressions (same syntax as SceneChoice.condition),
/// checked in order; the first match wins, otherwise [narrative] is used.
class SceneNode {
  final String sceneId;
  final String? illustrationId;
  final String narrative;
  final Map<String, String> narrativeVariants;
  final List<SceneChoice> choices;

  const SceneNode({
    required this.sceneId,
    this.illustrationId,
    required this.narrative,
    this.narrativeVariants = const {},
    required this.choices,
  });

  factory SceneNode.fromJson(Map<String, dynamic> json) {
    final choicesJson = (json['choices'] as List?) ?? const [];
    final variantsJson = (json['narrativeVariants'] as Map?) ?? const {};
    return SceneNode(
      sceneId: json['sceneId'] as String,
      illustrationId: json['illustrationId'] as String?,
      narrative: json['narrative'] as String,
      narrativeVariants: variantsJson.cast<String, String>(),
      choices: choicesJson
          .map((c) => SceneChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
