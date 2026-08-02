import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/npcs.dart';
import '../../engine/game_controller.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    // Safe to force-unwrap: JournalScreen is only ever pushed from
    // SceneScreen's bottom nav, which itself is only shown once a
    // character exists (see _AppRoot in main.dart).
    final character = controller.character!;
    final history = character.runHistory;
    final deceased = controller.world.deceasedHeroes;

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('This Life', style: GoogleFonts.cinzel(fontSize: 18)),
          Text(
            character.name,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('No notable deeds... yet.')
          else
            ...history.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $h'),
                )),
          const SizedBox(height: 24),

          // PROBLEM: the Honor System (Story & Systems Bible section 4)
          // had four reputation tracks and per-NPC trust, but nowhere
          // in the UI showed them - a mechanic the player can never see
          // might as well not exist. SOLUTION: a Reputation section
          // here, since Journal is already the "where do I stand right
          // now" screen. Deliberately shown as raw signed numbers, not
          // a 0-100 bar - the bible's whole point was that these can go
          // negative and don't collapse into one good/evil axis.
          Text('Reputation', style: GoogleFonts.cinzel(fontSize: 18)),
          const SizedBox(height: 8),
          _ReputationRow(label: 'Honor', value: character.reputation['honor'] ?? 0),
          _ReputationRow(label: 'Infamy', value: character.reputation['infamy'] ?? 0),
          _ReputationRow(label: 'Crown standing', value: character.reputation['crown'] ?? 0),
          _ReputationRow(
              label: 'Commonfolk standing',
              value: character.reputation['commonfolk'] ?? 0),
          if (character.npcTrust.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'People who remember you',
              style: GoogleFonts.cinzel(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            ...character.npcTrust.entries.map((entry) {
              final npc = Npcs.byId(entry.key);
              final status = character.npcStatus[entry.key] ?? 'alive';
              final displayName = npc?.displayName ?? entry.key;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status == 'alive' ? displayName : '$displayName ($status)',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      entry.value >= 0 ? '+${entry.value}' : '${entry.value}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: entry.value >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
          Text('The Chronicle (past lives)',
              style: GoogleFonts.cinzel(fontSize: 18)),
          const SizedBox(height: 8),
          if (deceased.isEmpty)
            const Text('No hero has yet fallen. You are the first.')
          else
            ...deceased.reversed.map((h) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${h.name}, ${h.title}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(
                          'Died ${h.yearOfDeath}, aged ${h.ageAtDeath} '
                          '(${h.causeOfDeath}) - ${h.alignment}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        ...h.majorCanonEvents.map(
                          (e) => Text('- $e', style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ReputationRow extends StatelessWidget {
  final String label;
  final int value;

  const _ReputationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value >= 0 ? '+$value' : '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: value > 0
                  ? Colors.green[700]
                  : (value < 0 ? Colors.red[700] : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
