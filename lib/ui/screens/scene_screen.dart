import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';
import '../../engine/settings_controller.dart';
import '../../models/scene_log_entry.dart';
import '../../models/scene_node.dart';
import '../widgets/choice_button.dart';
import '../widgets/narrative_text.dart';
import '../widgets/stat_bar.dart';
import 'death_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';

/// PROBLEM: this used to show exactly one scene at a time - picking a
/// choice replaced the whole reading area with the next scene, like
/// flipping a page rather than reading a continuous book. The user
/// wanted infinite scrolling: each choice appends the next block of
/// story below the current one, so earlier choices/text stay visible
/// (and re-readable) as you scroll up, like a visual-novel log.
///
/// SOLUTION: converted to a StatefulWidget so it can own a
/// ScrollController and auto-scroll to the bottom whenever
/// GameController.sceneLog grows - the actual list of what to render
/// now comes from `controller.sceneLog` (see game_controller.dart)
/// instead of a single `currentScene`.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  final _scrollController = ScrollController();
  int _lastRenderedLogLength = 0;
  bool _revealScrollQueued = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom AFTER the new entry has actually been laid
  /// out (addPostFrameCallback), since maxScrollExtent isn't correct
  /// until the frame with the new content has built.
  void _scrollToBottomIfGrew(int newLength) {
    if (newLength <= _lastRenderedLogLength) return;
    _lastRenderedLogLength = newLength;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  /// A new entry expands one line at a time. Keep the reading position
  /// attached to that expanding edge so a choice feels like the next passage
  /// is being revealed, rather than a completed page abruptly appearing below
  /// the viewport.
  void _followNarrativeReveal() {
    if (_revealScrollQueued) return;
    _revealScrollQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScrollQueued = false;
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        if (controller.isDead) {
          return const DeathScreen();
        }

        if (controller.currentScene == null || controller.sceneLog.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Trigger the auto-scroll check as part of build - cheap
        // (just an int compare) and guarantees it fires exactly once
        // per genuine log growth, regardless of what caused the rebuild.
        _scrollToBottomIfGrew(controller.sceneLog.length);

        final showRollBanner =
            context.watch<SettingsController>().settings.showRollBanner;

        return Scaffold(
          backgroundColor: const Color(0xFFE9E2D3), // parchment page
          body: SafeArea(
            child: Column(
              children: [
                // Safe to force-unwrap: reaching this line means isDead
                // was false and sceneLog/currentScene were non-empty
                // above, and GameController only ever has those non-null
                // while character is also non-null.
                StatBar(character: controller.character!),
                Container(height: 3, color: Colors.amber[800]),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < controller.sceneLog.length; i++)
                          _LogEntryView(
                            entry: controller.sceneLog[i],
                            isLatest: i == controller.sceneLog.length - 1,
                            arcTitle: i == controller.sceneLog.length - 1 &&
                                    controller.currentScene?.nodeType ==
                                        StoryNodeType.worldEvent
                                ? controller.currentScene?.arcTitle
                                : null,
                            animateNarrative:
                                i == controller.sceneLog.length - 1 &&
                                    controller.sceneLog.length > 1,
                            controller: controller,
                            showRollBanner: showRollBanner,
                            onNarrativeReveal: _followNarrativeReveal,
                          ),
                      ],
                    ),
                  ),
                ),
                _BottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renders one block of the scroll: its narrative + illustration, then
/// EITHER a small "you chose..." recap line (already-answered entries)
/// OR the live, tappable choice buttons (only ever true for the last
/// entry in the log).
class _LogEntryView extends StatelessWidget {
  final SceneLogEntry entry;
  final bool isLatest;
  final String? arcTitle;
  final bool animateNarrative;
  final GameController controller;
  final bool showRollBanner;
  final VoidCallback onNarrativeReveal;

  const _LogEntryView({
    required this.entry,
    required this.isLatest,
    this.arcTitle,
    required this.animateNarrative,
    required this.controller,
    required this.showRollBanner,
    required this.onNarrativeReveal,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyAnswered = entry.chosenLabel != null;
    final eventNotice = _WorldEventNotice.forScene(entry.sceneId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (arcTitle != null) _ArcTitleCard(title: arcTitle!),
          NarrativeText(
            text: entry.narrative,
            illustrationId: entry.illustrationId,
            animate: animateNarrative,
            onRevealProgress: onNarrativeReveal,
          ),
          if (alreadyAnswered)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right,
                      size: 14, color: Colors.brown[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.chosenLabel!,
                      style: GoogleFonts.merriweather(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.brown[500],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // This is the active/latest entry - show the roll result (if
            // any, and if the setting allows it) for the check that led
            // HERE, then the live choice buttons.
            if (showRollBanner && controller.lastCheckResult != null)
              _CheckResultBanner(result: controller.lastCheckResult!),
            if (eventNotice != null) _WorldEventNotice(text: eventNotice),
            const SizedBox(height: 8),
            ...controller.availableChoices.map(
              (choice) => ChoiceButton(
                label: choice.label,
                preview: choice.preview,
                onTap: controller.isSelectingChoice
                    ? null
                    : () => controller.selectChoice(choice),
              ),
            ),
          ],
          if (alreadyAnswered && entry.chosenAftermath != null)
            Container(
              margin: const EdgeInsets.only(left: 20, bottom: 8),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.brown.withOpacity(0.24))),
              ),
              child: Text(
                entry.chosenAftermath!,
                style: GoogleFonts.merriweather(
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.brown[600],
                ),
              ),
            ),
          if (alreadyAnswered)
            Divider(color: Colors.brown.withOpacity(0.15), height: 24),
        ],
      ),
    );
  }
}

/// A quiet scale marker. It tells the reader an arc has turned without
/// interrupting the prose with a modal or a game-like chapter screen.
class _ArcTitleCard extends StatelessWidget {
  final String title;

  const _ArcTitleCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Divider(color: Colors.brown.withOpacity(0.25)),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 13,
              letterSpacing: 1.3,
              color: Colors.brown[700],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.brown.withOpacity(0.25)),
        ],
      ),
    );
  }
}

/// Kept deliberately small: this is a breath before a major turn, not a
/// quest marker or a warning modal. The story itself remains the context.
class _WorldEventNotice extends StatelessWidget {
  final String text;

  const _WorldEventNotice({required this.text});

  static const _notices = <String, String>{
    'event1_coda': 'Approaching world event · The War with the Northern Reach',
    'event2_coda': 'The realm is changing again.',
    'event3_coda': 'Approaching world event · Sickness in the Hollow Reaches',
    'event4_coda': 'Approaching world event · The Succession Crisis',
    'event5_coda': 'Approaching world event · Strange sails in the west',
    'event6_coda': 'Approaching world event · The Dark Legion',
    'event7_realm_falls': 'The final world event is approaching.',
  };

  static String? forScene(String sceneId) => _notices[sceneId];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Container(width: 18, height: 1, color: Colors.brown[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: GoogleFonts.merriweather(
                fontSize: 10,
                letterSpacing: 0.9,
                color: Colors.brown[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckResultBanner extends StatelessWidget {
  final dynamic result; // StatCheckResult

  const _CheckResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result.success as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Roll: ${result.roll} + ${result.modifier} = ${result.total} '
        'vs DC ${result.difficultyClass} - ${success ? "Success" : "Failure"}',
        style: TextStyle(
          color: success ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Non-destructive: every choice already autosaves via
/// SaveManager.saveRun(), so leaving mid-scroll and returning via
/// "Continue" resumes exactly where sceneLog left off (see
/// GameController.resumeGame - it only rebuilds the log from scratch if
/// it's empty, which it won't be after a same-session round trip).
class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();

    return Container(
      color: const Color(0xFFCFC7B8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Main Menu',
            onPressed: controller.goToMainMenu,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Journal',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JournalScreen()),
              );
            },
          ),
          const IconButton(
            icon: Icon(Icons.inventory_2_outlined),
            onPressed: null, // Phase 2: build inventory screen
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
