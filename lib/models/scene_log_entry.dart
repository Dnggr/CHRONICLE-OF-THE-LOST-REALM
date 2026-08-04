import 'scene_node.dart';

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
///
/// PROBLEM (UI pass, this session): SceneScreen used to render the
/// "still answering this entry" choice buttons straight from
/// `GameController.availableChoices` - a LIVE getter that reads
/// `currentScene`. That was fine while the entry really was the only
/// live one, but the new confirm-then-collapse animation (see
/// ChoiceButton/SceneScreen changes) needs to keep showing THIS entry's
/// buttons - with one highlighted, the rest dimmed - for a short beat
/// AFTER the player has already tapped one. By that point
/// `GameController` has already moved `currentScene` on to the NEXT
/// scene (so the choice can be validated/saved), so the live getter
/// would silently start rendering the WRONG (next scene's) choices
/// part-way through the confirm animation.
/// SOLUTION: freeze the choices this entry actually offered at the
/// moment it was appended to the log, the same way `narrative` is
/// already frozen. The confirm/dim animation now reads from
/// `entry.choices` instead of the live getter, so it can never drift
/// out from under itself no matter how far the controller has already
/// progressed underneath it.
class SceneLogEntry {
  final String sceneId;
  final String narrative;
  final String? illustrationId;

  /// The choices this entry offered, frozen at the moment it was
  /// appended (same filtering `GameController.availableChoices` would
  /// have applied at that instant). Used to render both the live
  /// button list AND the brief "you picked this one" confirm state -
  /// never re-derived from `currentScene` later, so it can't drift.
  final List<SceneChoice> choices;

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
    required this.choices,
    this.illustrationId,
    this.chosenLabel,
    this.chosenAftermath,
  });
}
