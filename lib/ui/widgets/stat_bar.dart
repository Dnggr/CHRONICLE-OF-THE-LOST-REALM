import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portraits.dart';
import '../../models/character_state.dart';

/// Recreates the top bar from the reference screenshot: portrait + name
/// on the left, a grid of small stat readouts on the right.
///
/// STR/DEX/INT/WIS/CHA/CON matches Life in Adventure's D&D-style 6-stat
/// system (see DEVLOG.md Session 4) - not a custom stat set.
///
/// PROBLEM: the avatar used to always show a plain letter regardless of
/// character - once CharacterCreationScreen added a real Portrait
/// picker (Session 5), the top bar needed to actually reflect it, or
/// the picker would feel decorative. SOLUTION: look up
/// character.portraitId in the Portraits registry and render its
/// icon/color instead of a letter.
///
/// PROBLEM (UI pass, this session): health and gold just snapped to
/// their new value the instant a choice applied an effect - easy to
/// miss entirely if you weren't already looking at the top bar, and
/// out of step with the rest of the pass's "make it relaxing to read"
/// goal. SOLUTION: both readouts now animate through the change
/// (a short count/crossfade) via AnimatedSwitcher + TweenAnimationBuilder,
/// so a gold cost or a wound registers as something that visibly
/// happened rather than a static number that was just... different now.
class StatBar extends StatelessWidget {
  final CharacterState character;

  const StatBar({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    final attrs = character.attributes;
    final portrait = Portraits.byId(character.portraitId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFCFC7B8), // parchment/tan like the reference
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: portrait.color,
            child: Icon(portrait.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _StatChip(label: 'STR', value: attrs['strength'] ?? 0),
                    _StatChip(label: 'DEX', value: attrs['dexterity'] ?? 0),
                    _StatChip(label: 'INT', value: attrs['intelligence'] ?? 0),
                    _StatChip(label: 'WIS', value: attrs['wisdom'] ?? 0),
                    _StatChip(label: 'CHA', value: attrs['charisma'] ?? 0),
                    _StatChip(label: 'CON', value: attrs['constitution'] ?? 0),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 4),
                    _AnimatedReadout(
                      text: '${character.healthCurrent}/${character.healthMax}',
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.circle, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    _AnimatedReadout(text: '${character.gold}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small readout (health, gold) that crossfades + rises into its new
/// value instead of snapping. Keyed by the text itself so
/// AnimatedSwitcher only plays the transition when the value actually
/// changes, not on every unrelated rebuild of StatBar.
class _AnimatedReadout extends StatelessWidget {
  final String text;

  const _AnimatedReadout({required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        text,
        key: ValueKey(text),
        style:
            GoogleFonts.merriweather(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
