import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/archetypes.dart';
import '../../engine/game_controller.dart';

/// PHASE UPDATE: this used to be an unwired scaffold that only asked for
/// a name. PROBLEM: the user wanted real build variety at the start of
/// each life (Wanderer / Civilian / royalty / Elf / Dwarf / Vampire /
/// Mercenary), each with mechanical perks AND narrative hooks, and they
/// wanted this to run both on first launch and after every death.
/// SOLUTION: this screen now does two things in one flow - name entry,
/// then an archetype grid - and GameController routes here automatically
/// via needsCharacterCreation, so main.dart and DeathScreen don't need
/// any special-case logic for "first ever run" vs "run after death."
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _nameController = TextEditingController();
  Archetype? _selected;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    final hasPastHeroes = controller.world.deceasedHeroes.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1712),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Text(
                    'Chronicle of the Lost Realm',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      color: Colors.amber[200],
                      fontSize: 22,
                    ),
                  ),
                  if (hasPastHeroes) ...[
                    const SizedBox(height: 8),
                    Text(
                      // STORY NOTE: this line is the player-facing proof
                      // that the legacy system is real - it only shows
                      // once a hero has actually died and been recorded.
                      'The realm remembers ${controller.world.deceasedHeroes.length} '
                      'who came before you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.merriweather(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Name your adventurer',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber[700]!),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber[400]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: Archetypes.all.length,
                itemBuilder: (context, index) {
                  final archetype = Archetypes.all[index];
                  final isSelected = archetype.id == _selected?.id;
                  return _ArchetypeCard(
                    archetype: archetype,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selected = archetype),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          final name = _nameController.text.trim();
                          controller.beginRun(
                            name: name.isEmpty ? _selected!.displayName : name,
                            archetype: _selected!,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Begin Your Chronicle'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchetypeCard extends StatelessWidget {
  final Archetype archetype;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArchetypeCard({
    required this.archetype,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isSelected ? Colors.amber.withOpacity(0.15) : const Color(0xFF262019),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.amber[400]! : Colors.white12,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      archetype.displayName,
                      style: GoogleFonts.cinzel(
                        color: Colors.amber[100],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.amber[400], size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                archetype.tagline,
                style: GoogleFonts.merriweather(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                archetype.description,
                style: GoogleFonts.merriweather(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              if (archetype.perkSummary.isNotEmpty)
                Text(
                  archetype.perkSummary,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (archetype.startingInventory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Starts with: ${archetype.startingInventory.join(', ')}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
