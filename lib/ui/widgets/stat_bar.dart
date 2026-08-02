import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/character_state.dart';

/// Recreates the top bar from the reference screenshot: portrait + name
/// on the left, a grid of small stat readouts on the right.
///
/// STR/DEX/INT/WIS/CHA/CON matches Life in Adventure's D&D-style 6-stat
/// system (see DEVLOG.md Session 4) - not a custom stat set.
class StatBar extends StatelessWidget {
  final CharacterState character;

  const StatBar({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    final attrs = character.attributes;

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
            backgroundColor: Colors.black26,
            child: Text(
              character.name.isNotEmpty
                  ? character.name[0].toUpperCase()
                  : '?',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
                    Text('${character.healthCurrent}/${character.healthMax}'),
                    const SizedBox(width: 12),
                    const Icon(Icons.circle, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${character.gold}'),
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
