import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final history = controller.character.runHistory;
    final deceased = controller.world.deceasedHeroes;

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('This Life', style: GoogleFonts.cinzel(fontSize: 18)),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('No notable deeds... yet.')
          else
            ...history.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $h'),
                )),
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
                          '(${h.causeOfDeath})',
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
