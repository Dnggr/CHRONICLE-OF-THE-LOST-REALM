import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';

class DeathScreen extends StatefulWidget {
  const DeathScreen({super.key});

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  final _nameController = TextEditingController();

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
                    '${hero.name} died in the year ${hero.yearOfDeath}, '
                    'aged ${hero.ageAtDeath}.\nCause: ${hero.causeOfDeath}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.merriweather(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
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
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Name your new hero',
                    hintStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber[700]!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    controller.startNewRunAfterDeath(
                      name: name.isEmpty ? 'Wanderer' : name,
                    );
                  },
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
