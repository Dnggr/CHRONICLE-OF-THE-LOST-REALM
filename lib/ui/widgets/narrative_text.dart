import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders narrative prose in a serif "book page" style, with an
/// optional illustration dropped inline (matching the reference
/// screenshot, where the image sits between two blocks of text).
///
/// [illustrationId] maps to assets/images/illustrations/<id>.png.
/// If the asset is missing (e.g. you haven't added art yet), this
/// widget shows a placeholder box instead of crashing - useful while
/// you're still writing scenes before sourcing final art.
///
/// PROBLEM (this session): scene JSON had no way to write actual
/// back-and-forth dialogue - every line rendered as plain narration
/// prose, even a line like `"No understand. This is happy, question?"`
/// with no indication of who's speaking. The reference screenplay
/// excerpt shows the format the user wants: a centered/indented
/// character name, then their line below it, with italics used for
/// emphasis. SOLUTION: added a small text markup scene writers can use
/// directly inside a `narrative` string in JSON:
///   - a line starting with `@Name: ` renders as a screenplay-style
///     dialogue block (name label above, indented line below), instead
///     of a plain paragraph.
///   - `_word or phrase_` (inside ANY line, narration or dialogue)
///     renders in italics, for the kind of mid-sentence emphasis the
///     reference script uses ("The _exact opposite_ of the stoic
///     demeanor...").
/// No new JSON fields were needed - this all lives inside the existing
/// `narrative`/`narrativeVariants` strings, so every scene already
/// written keeps working unchanged; only scenes that opt into the `@`
/// prefix get the dialogue treatment.
class NarrativeText extends StatelessWidget {
  final String text;
  final String? illustrationId;

  /// When a player has just selected a choice, the next story block unfolds
  /// line-by-line instead of appearing fully rendered below the scroll.
  final bool animate;
  final VoidCallback? onRevealProgress;

  static final RegExp _dialoguePattern = RegExp(r'^@([^:]+):\s*(.*)$');
  static final RegExp _emphasisPattern = RegExp(r'_(.+?)_');

  static const _proseColor = Color(0xFF2A2420);

  const NarrativeText({
    super.key,
    required this.text,
    this.illustrationId,
    this.animate = false,
    this.onRevealProgress,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...(() {
          final widgets = <Widget>[];
          var revealIndex = 0;
          Widget reveal(Widget child) {
            final index = revealIndex++;
            if (!animate) return child;
            return _RevealLine(
              delay: Duration(milliseconds: index * 75),
              onProgress: onRevealProgress,
              child: child,
            );
          }

          for (final rawLine in lines) {
            final line = rawLine;
            final trimmed = line.trim();
            final dialogueMatch = _dialoguePattern.firstMatch(trimmed);

            if (trimmed.startsWith('+') || trimmed.startsWith('-')) {
              widgets.add(reveal(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    trimmed,
                    style: GoogleFonts.merriweather(
                      fontSize: 14,
                      color: trimmed.startsWith('+')
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ));
            } else if (dialogueMatch != null) {
              widgets.add(reveal(_DialogueLine(
                speaker: dialogueMatch.group(1)!.trim(),
                line: dialogueMatch.group(2)!.trim(),
              )));
            } else if (trimmed.isEmpty) {
              widgets.add(reveal(const SizedBox(height: 12)));
            } else {
              widgets.add(reveal(
                Text.rich(
                  TextSpan(
                    children: _emphasisSpans(
                      line,
                      GoogleFonts.merriweather(
                        fontSize: 16,
                        height: 1.5,
                        color: _proseColor,
                      ),
                    ),
                  ),
                ),
              ));
            }
          }
          return widgets;
        })(),
        if (illustrationId != null) ...[
          const SizedBox(height: 16),
          _Illustration(illustrationId: illustrationId!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Splits [source] on `_..._` runs, returning alternating normal/
  /// italic TextSpans built from [baseStyle]. Shared by both plain
  /// narration lines and _DialogueLine below, so emphasis markup works
  /// identically in either.
  static List<TextSpan> _emphasisSpans(String source, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _emphasisPattern.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start), style: baseStyle));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
      cursor = match.end;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor), style: baseStyle));
    }
    return spans;
  }
}

/// A small, staggered reveal is intentionally used instead of a character
/// typewriter: the latter would briefly mis-parse `@Name:` dialogue markup
/// while only half a speaker tag had appeared. Expanding complete lines keeps
/// screenplay dialogue formatted correctly throughout the animation.
class _RevealLine extends StatefulWidget {
  final Duration delay;
  final VoidCallback? onProgress;
  final Widget child;

  const _RevealLine({
    required this.delay,
    required this.onProgress,
    required this.child,
  });

  @override
  State<_RevealLine> createState() => _RevealLineState();
}

class _RevealLineState extends State<_RevealLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(widget.onProgress ?? () {});
    _startAfterDelay();
  }

  Future<void> _startAfterDelay() async {
    await Future<void>.delayed(widget.delay);
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Screenplay-style dialogue block: an all-caps, letter-spaced speaker
/// name, then the line indented below it. Deliberately kept in the same
/// Merriweather serif family as the rest of the app (rather than
/// switching to a literal Courier/monospace screenplay font) so
/// dialogue doesn't visually clash with the surrounding prose - the
/// STRUCTURE (name callout + indented line) is what was requested, not
/// literal screenplay typesetting.
class _DialogueLine extends StatelessWidget {
  final String speaker;
  final String line;

  const _DialogueLine({required this.speaker, required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              speaker.toUpperCase(),
              style: GoogleFonts.merriweather(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
                color: const Color(0xFF6B4B2A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 12, top: 2),
            child: Text.rich(
              TextSpan(
                children: NarrativeText._emphasisSpans(
                  line,
                  GoogleFonts.merriweather(
                    fontSize: 15,
                    height: 1.4,
                    color: NarrativeText._proseColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final String illustrationId;

  const _Illustration({required this.illustrationId});

  @override
  Widget build(BuildContext context) {
    final path = 'assets/images/illustrations/$illustrationId.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 180,
          alignment: Alignment.center,
          color: Colors.black12,
          child: Text(
            '[ illustration: $illustrationId ]',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
