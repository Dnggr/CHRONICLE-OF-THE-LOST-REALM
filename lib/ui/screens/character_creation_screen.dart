import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';

/// PHASE 2 SCAFFOLD - not yet wired into main.dart's initial route.
///
/// Right now GameController.init() auto-creates a "Wanderer" character
/// so Phase 1 (the reading/choice engine) can be tested end to end
/// without blocking on this screen. When you get to Phase 2, swap
/// main.dart to show this screen first on a fresh install (no saved
/// run + no deceased heroes yet), call
/// `controller.startNewRunAfterDeath(name: ...)` from the Begin button
/// below, then navigate to SceneScreen.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();

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
                  'Chronicle of the Lost Realm',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: Colors.amber[200],
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Name your adventurer',
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
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Begin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
