/// PROBLEM: SceneScreen used to show exactly ONE scene at a time -
/// picking a choice replaced the whole screen's content with the next
/// scene, closer to flipping a page than reading a continuous book. The
/// user wanted an infinite-scroll feed instead: each choice APPENDS the
/// next block of story below the current one, like a visual-novel log,
/// so the player can scroll back up and re-read earlier choices/text in
/// the same session.
///
/// SOLUTION: GameController now keeps a `List<SceneLogEntry>` (see
/// `sceneLog` in game_controller.dart) instead of just a single
/// `currentScene`. Each entry is a frozen snapshot of one scene's
/// resolved text (narrativeVariants already picked, baked in at the
/// moment the scene was entered - like a book page, it doesn't
/// retroactively change if world state changes later) plus which choice
/// the player picked FROM that entry, once they've picked one. The last
/// entry in the list (chosenLabel == null) is the only one still
/// showing live, tappable choice buttons.
///
/// SCOPE NOTE: this log lives in memory only for the current play
/// session - it is NOT persisted to disk. Closing and reopening the app
/// (or hitting Continue after a cold start) resumes at your saved scene
/// with a fresh single-entry log, not the full multi-scene scroll from
/// before. Full session persistence is a reasonable next step but adds
/// save-format risk that wasn't worth taking in the same change as the
/// stat-system rename and the button contrast fix - see DEVLOG.md
/// Session 4.
class SceneLogEntry {
  final String sceneId;
  final String narrative;
  final String? illustrationId;

  /// Null while this is still the active/latest entry awaiting a
  /// choice. Set to the chosen SceneChoice's label once the player taps
  /// one, at which point a new SceneLogEntry gets appended after it.
  String? chosenLabel;

  /// The immediate emotional or physical response to [chosenLabel]. This is
  /// kept with the answered entry so it stays visible between the choice and
  /// the next scene in the continuous reading log.
  String? chosenAftermath;

  SceneLogEntry({
    required this.sceneId,
    required this.narrative,
    this.illustrationId,
    this.chosenLabel,
    this.chosenAftermath,
  });
}
