import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';

/// PROBLEM this screen used to have: it asked for the new hero's name
/// directly and called a (now-removed) generic startNewRunAfterHome(name)
/// that skipped archetype selection entirely - so every resurrection was
/// mechanically identical, defeating the whole point of adding origins.
/// SOLUTION: DeathScreen's only job now is showing the recap. Tapping
/// "Continue" calls GameController.acknowledgeDeath(), which flips
/// isDead off; that makes needsCharacterCreation true, and _AppRoot
/// (see main.dart) routes to CharacterCreationScreen automatically -
/// where the player picks BOTH a name and an archetype for their next
/// life, same as their very first character.
class DeathScreen extends StatelessWidget {
  const DeathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final hero = controller.world.mostRecentHero;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1712),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'The Chronicle Remembers',
                  style: GoogleFonts.cinzel(
                    color: Colors.amber[200],
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 16),
                if (hero != null)
                  Text(
                    '${hero.name}, ${hero.title}, died in the year '
                    '${hero.yearOfDeath}, aged ${hero.ageAtDeath}.\n'
                    'Cause: ${hero.causeOfDeath}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.merriweather(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                if (hero != null && hero.majorCanonEvents.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...hero.majorCanonEvents.map(
                    (event) => Text(
                      '- $event',
                      style: GoogleFonts.merriweather(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Their deeds are now canon. The world will remember.',
                  style: GoogleFonts.merriweather(
                    color: Colors.white38,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: controller.acknowledgeDeath,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Begin a New Legend'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
