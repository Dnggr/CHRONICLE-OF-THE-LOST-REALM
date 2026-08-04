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
///
/// PROBLEM (UI pass, this session): the user reported that clicking a
/// choice "sucks" - specifically two things, both traced back to this
/// file and its children:
///   1. The moment you tapped a choice, EVERY button in the list went
///      uniformly gray/disabled with no sense of which one you'd
///      picked, then the whole block vanished in favor of a tiny recap
///      line - an instant, unanimated swap.
///   2. While the next block's text revealed itself, the scroll
///      position visibly juddered - traced to `_followNarrativeReveal`
///      being called on every animation FRAME instead of once per
///      line (see narrative_text.dart for the actual fix) and to a
///      second, competing scroll-to-bottom animation firing at the
///      same time as that per-line follow.
/// SOLUTION: see `_LogEntryView` for the new confirm-then-collapse
/// transition (AnimatedSwitcher + ChoiceButton's isChosen/isDimmed
/// states), and `_followNarrativeReveal` below for the de-juddered,
/// single-source scroll-follow.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// A new entry expands one line at a time. Keep the reading position
  /// attached to that expanding edge so a choice feels like the next
  /// passage is being revealed, rather than a completed page abruptly
  /// appearing below the viewport.
  ///
  /// PROBLEM: this used to be called on every animation tick of every
  /// line (see narrative_text.dart's old `addListener`) and used
  /// `jumpTo`, a hard instant re-snap - stacked across ~15 ticks per
  /// line, across every line in a block, that's what actually produced
  /// the "sucks" judder. It was ALSO a second scroll mechanism running
  /// concurrently with a separate `animateTo` call that used to fire
  /// whenever `sceneLog` grew, fighting over the scroll position.
  /// SOLUTION: narrative_text.dart now calls this once per LINE
  /// (on that line's reveal completing, not on every frame), and this
  /// is now the single, only scroll-follow mechanism in the screen - the
  /// old separate "on log growth" scroll call has been removed entirely
  /// rather than reconciled, since this one already covers every case
  /// that mattered (a fresh scene always animates in, so its own line
  /// completions always carry the scroll down to meet it).
  void _followNarrativeReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
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
/// entry in the log) - and, in between those two, a brief confirm beat
/// on the exact button that was tapped.
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
    final eventNotice = _WorldEventNotice.forScene(entry.sceneId);

    // PROBLEM (UI pass, this session): the old code branched purely on
    // `entry.chosenLabel != null` - meaning the instant a choice was
    // tapped (and chosenLabel got written), the whole block already
    // switched to the recap line with nothing in between. SOLUTION:
    // a third, brief state - "confirming" - covers the window between
    // "tapped" and "the next scene is actually ready" (see
    // GameController.selectChoice's minFeedback delay). Only the entry
    // that's both still `isLatest` AND mid-selection can be confirming;
    // the instant the next entry is appended, `isLatest` flips false
    // for THIS entry and it falls straight through to the recap state.
    final isConfirming =
        isLatest && controller.isSelectingChoice && entry.chosenLabel != null;
    final showingRecap = entry.chosenLabel != null && !isConfirming;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (arcTitle != null)
            _EntranceFade(child: _ArcTitleCard(title: arcTitle!)),
          NarrativeText(
            text: entry.narrative,
            illustrationId: entry.illustrationId,
            animate: animateNarrative,
            onRevealProgress: onNarrativeReveal,
          ),
          // PROBLEM: the choices-vs-recap swap used to happen instantly,
          // mid-frame, with no transition at all - the single biggest
          // contributor to the "clicking a choice sucks" complaint.
          // SOLUTION: AnimatedSwitcher cross-fades + collapses the
          // height between the two states instead of popping between
          // them. Each branch gets a stable ValueKey so the switcher
          // can tell them apart.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: showingRecap
                ? _RecapLine(key: const ValueKey('recap'), entry: entry)
                : _ChoiceList(
                    key: const ValueKey('choices'),
                    entry: entry,
                    controller: controller,
                    showRollBanner: showRollBanner,
                    eventNotice: eventNotice,
                    isConfirming: isConfirming,
                  ),
          ),
          // The aftermath line only appears once the block has actually
          // settled into the recap state - showing it during the brief
          // confirm beat (while the chosen button is still highlighted
          // above) would have it competing for attention with that
          // animation.
          if (showingRecap && entry.chosenAftermath != null)
            Container(
              margin: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: Colors.brown.withOpacity(0.24))),
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
          if (showingRecap)
            Divider(color: Colors.brown.withOpacity(0.15), height: 24),
        ],
      ),
    );
  }
}

/// The live/confirming half of the AnimatedSwitcher in [_LogEntryView].
/// Reads choices from `entry.choices` (frozen at the moment this entry
/// was created) rather than the controller's live `availableChoices` -
/// see the doc comment on `SceneLogEntry.choices` for why that matters
/// once the controller has already moved `currentScene` on to the next
/// scene during the confirm beat.
class _ChoiceList extends StatelessWidget {
  final SceneLogEntry entry;
  final GameController controller;
  final bool showRollBanner;
  final String? eventNotice;
  final bool isConfirming;

  const _ChoiceList({
    super.key,
    required this.entry,
    required this.controller,
    required this.showRollBanner,
    required this.eventNotice,
    required this.isConfirming,
  });

  @override
  Widget build(BuildContext context) {
    final stillDeciding = entry.chosenLabel == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The roll banner/world-event notice describe how the player
        // ARRIVED at this entry, not the choice they're about to make -
        // once a choice has actually been tapped, `lastCheckResult`
        // will start describing the NEXT scene instead, so these are
        // only shown while genuinely still deciding.
        if (stillDeciding) ...[
          if (showRollBanner && controller.lastCheckResult != null)
            _CheckResultBanner(result: controller.lastCheckResult!),
          if (eventNotice != null)
            _EntranceFade(child: _WorldEventNotice(text: eventNotice!)),
          const SizedBox(height: 8),
        ],
        ...entry.choices.map((choice) {
          final isThisChosen = entry.chosenLabel == choice.label;
          return ChoiceButton(
            label: choice.label,
            preview: choice.preview,
            onTap: entry.chosenLabel != null
                ? null
                : () => controller.selectChoice(choice),
            isChosen: isConfirming && isThisChosen,
            isDimmed: isConfirming && !isThisChosen,
          );
        }),
      ],
    );
  }
}

/// The settled/answered half of the AnimatedSwitcher in [_LogEntryView].
class _RecapLine extends StatelessWidget {
  final SceneLogEntry entry;

  const _RecapLine({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right,
              size: 14, color: Colors.brown[400]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.chosenLabel ?? '',
              style: GoogleFonts.merriweather(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.brown[500],
              ),
            ),
          ),
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

/// A gentle, self-driving fade+rise used for anything that should ease
/// into view the first time it appears (arc title cards, world-event
/// notices) instead of popping in at full opacity. Built on
/// TweenAnimationBuilder rather than a StatefulWidget of its own -
/// Flutter preserves its internal AnimationController across rebuilds
/// at the same tree position, so it plays once on first mount and never
/// replays just because a parent rebuilt.
class _EntranceFade extends StatelessWidget {
  final Widget child;

  const _EntranceFade({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: child,
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
