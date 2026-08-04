import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A choice should read like a line the player is about to speak, not like a
/// large call-to-action. The short underline and quiet arrow make it legible
/// without competing with the prose above it.
///
/// PROBLEM (UI pass, this session): the user specifically flagged that
/// tapping a choice "sucks" - what actually happened under the hood was
/// every button just going uniformly gray/disabled the instant you
/// tapped ANY of them, with no indication of which one you'd actually
/// picked, followed by all of them vanishing at once in favor of a tiny
/// recap line. There was no moment where the interface visibly agreed
/// with you about what you'd just chosen.
/// SOLUTION: two new, optional visual states layered on top of the
/// existing press animation:
///   - [isChosen]: this is the exact button the player tapped. It gets
///     a warm filled background, a small check mark, and a slightly
///     bolder label - a clear "yes, this one" beat instead of just
///     going gray.
///   - [isDimmed]: a sibling button that WASN'T picked. It fades and
///     shrinks slightly rather than turning the same flat gray as
///     "chosen", so the two states read as opposites at a glance
///     instead of both just looking "off".
/// SceneScreen now holds a still-answered entry on screen in this
/// chosen/dimmed state for a short beat (see GameController's
/// `minFeedback` delay) before collapsing the whole block into the
/// small recap line via an AnimatedSwitcher, instead of popping
/// straight from "live buttons" to "recap" with nothing in between.
class ChoiceButton extends StatefulWidget {
  final String label;
  final String? preview;
  final VoidCallback? onTap;

  /// True only for the single button the player actually tapped, during
  /// the brief window between tapping and the block collapsing into the
  /// recap line. Mutually exclusive with [isDimmed].
  final bool isChosen;

  /// True for every OTHER button in the same list once one of them has
  /// been chosen. Mutually exclusive with [isChosen].
  final bool isDimmed;

  const ChoiceButton({
    super.key,
    required this.label,
    this.preview,
    required this.onTap,
    this.isChosen = false,
    this.isDimmed = false,
  });

  @override
  State<ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final baseColor = enabled ? const Color(0xFF3A2E22) : Colors.brown[300]!;
    final color = widget.isChosen ? const Color(0xFF3A2E22) : baseColor;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.isChosen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          borderRadius: BorderRadius.circular(4),
          splashColor: Colors.brown.withOpacity(0.08),
          highlightColor: Colors.brown.withOpacity(0.04),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : (widget.isChosen ? 1.01 : 1),
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              // The un-picked siblings fade back rather than flatten to
              // gray, so "not chosen" reads as visually distinct from
              // "disabled because the whole app is busy" elsewhere.
              opacity: widget.isDimmed ? 0.38 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                decoration: BoxDecoration(
                  color: widget.isChosen
                      ? Colors.amber.withOpacity(0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isChosen
                          ? Colors.brown[600]!
                          : (_pressed
                              ? Colors.brown[500]!
                              : Colors.brown.withOpacity(0.18)),
                      width: widget.isChosen ? 1.4 : 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 140),
                      offset: _pressed ? const Offset(0.16, 0) : Offset.zero,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, right: 10),
                        child: widget.isChosen
                            ? Icon(Icons.check_rounded, size: 18, color: color)
                            : Text('›',
                                style: TextStyle(fontSize: 22, color: color)),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 140),
                            style: GoogleFonts.merriweather(
                              fontSize: 14,
                              height: 1.45,
                              color: color,
                              fontWeight: (_pressed || widget.isChosen)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            child: Text(widget.label),
                          ),
                          if (widget.preview != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.preview!,
                              style: GoogleFonts.merriweather(
                                fontSize: 11,
                                height: 1.35,
                                color: Colors.brown[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
