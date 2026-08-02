import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/archetypes.dart';
import '../../data/backgrounds.dart';
import '../../data/equipment_kits.dart';
import '../../data/portraits.dart';
import '../../data/traits.dart';
import '../../engine/game_controller.dart';

/// PROBLEM: the original creation screen was just a name field + an
/// archetype grid - much shallower than the reference game's chargen
/// (Name / Gender / Portrait / Background / Trait / Stat Distribution /
/// Starting Equipment, all as separate layers - see the screenshot this
/// session's request was built from). SOLUTION: this screen now walks
/// through every one of those layers as its own section, all feeding
/// into a single CharacterState.fromCreationData call (see
/// character_state.dart) so nothing about the final character depends
/// on scattered logic across the UI.
///
/// Kept as ONE scrollable form rather than the reference's numbered
/// multi-step wizard (the "1 / 2 / 3" tabs in the screenshot) - a full
/// step-by-step wizard is a reasonable follow-up, but a single form
/// gets all the same DATA depth in front of the player with far less
/// new navigation/state-machine code to get right on the first pass.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  static const List<String> _genders = ['Male', 'Female', 'Nonbinary'];
  static const List<String> _statOrder = [
    'strength',
    'dexterity',
    'intelligence',
    'wisdom',
    'charisma',
    'constitution',
  ];
  static const int _baseStatValue = 8;
  static const int _maxStatValue = 15;
  static const int _pointPool = 12;

  final _nameController = TextEditingController();

  String _gender = _genders.first;
  int _portraitIndex = 0;
  Background _background = Backgrounds.all.first;
  Trait _trait = Traits.all.first;
  Archetype? _archetype;
  EquipmentKit _equipmentKit = EquipmentKits.all.first;

  late Map<String, int> _statAllocation = {
    for (final key in _statOrder) key: _baseStatValue,
  };

  int get _pointsSpent =>
      _statAllocation.values.fold(0, (sum, v) => sum + v) -
      (_statOrder.length * _baseStatValue);

  int get _pointsRemaining => _pointPool - _pointsSpent;

  void _incrementStat(String key) {
    if (_pointsRemaining <= 0) return;
    if ((_statAllocation[key] ?? _baseStatValue) >= _maxStatValue) return;
    setState(() => _statAllocation[key] = _statAllocation[key]! + 1);
  }

  void _decrementStat(String key) {
    if ((_statAllocation[key] ?? _baseStatValue) <= _baseStatValue) return;
    setState(() => _statAllocation[key] = _statAllocation[key]! - 1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    final portrait = Portraits.all[_portraitIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1B1712),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.amber[200]),
                tooltip: 'Back to menu',
                onPressed: controller.goToMainMenu,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Text(
                    'Chronicle of the Lost Realm',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      color: Colors.amber[100],
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('Name'),
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

                  const _SectionLabel('Gender'),
                  _DarkDropdown<String>(
                    value: _gender,
                    items: _genders,
                    labelBuilder: (g) => g,
                    onChanged: (g) => setState(() => _gender = g),
                  ),

                  const _SectionLabel('Portrait'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white54),
                        onPressed: () => setState(() {
                          _portraitIndex =
                              (_portraitIndex - 1 + Portraits.all.length) %
                                  Portraits.all.length;
                        }),
                      ),
                      Expanded(
                        child: Center(
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: portrait.color,
                            child: Icon(portrait.icon, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white54),
                        onPressed: () => setState(() {
                          _portraitIndex = (_portraitIndex + 1) % Portraits.all.length;
                        }),
                      ),
                    ],
                  ),

                  const _SectionLabel('Background'),
                  _DarkDropdown<Background>(
                    value: _background,
                    items: Backgrounds.all,
                    labelBuilder: (b) => b.displayName,
                    onChanged: (b) => setState(() => _background = b),
                  ),
                  _PerkCaption(
                    description: _background.description,
                    perkSummary: _background.perkSummary,
                  ),

                  const _SectionLabel('Trait'),
                  _DarkDropdown<Trait>(
                    value: _trait,
                    items: Traits.all,
                    labelBuilder: (t) => t.displayName,
                    onChanged: (t) => setState(() => _trait = t),
                  ),
                  _PerkCaption(
                    description: _trait.description,
                    perkSummary: _trait.perkSummary,
                  ),

                  const _SectionLabel('Origin'),
                  Text(
                    'Your race/origin - determines how the world reacts to '
                    'you throughout the story.',
                    style: GoogleFonts.merriweather(
                      color: Colors.white54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...Archetypes.all.map(
                    (archetype) => _ArchetypeCard(
                      archetype: archetype,
                      isSelected: archetype.id == _archetype?.id,
                      onTap: () => setState(() => _archetype = archetype),
                    ),
                  ),

                  const _SectionLabel('Stat Distribution'),
                  _StatDistribution(
                    allocation: _statAllocation,
                    order: _statOrder,
                    pointsRemaining: _pointsRemaining,
                    onIncrement: _incrementStat,
                    onDecrement: _decrementStat,
                  ),

                  const _SectionLabel('Starting Equipment'),
                  _DarkDropdown<EquipmentKit>(
                    value: _equipmentKit,
                    items: EquipmentKits.all,
                    labelBuilder: (k) => k.displayName,
                    onChanged: (k) => setState(() => _equipmentKit = k),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_equipmentKit.description} Grants: '
                      '${_equipmentKit.items.join(', ')}.',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _archetype == null
                          ? null
                          : () {
                              final name = _nameController.text.trim();
                              controller.beginRun(
                                name: name.isEmpty ? _archetype!.displayName : name,
                                gender: _gender,
                                portraitId: portrait.id,
                                archetype: _archetype!,
                                background: _background,
                                trait: _trait,
                                equipmentKit: _equipmentKit,
                                baseAttributes: _statAllocation,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Begin!'),
                    ),
                  ),
                  if (_archetype == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Pick an Origin below to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.cinzel(
          color: Colors.amber[300],
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Small dark-themed dropdown shared by Gender/Background/Trait/Equipment
/// - factored out once it was needed a fourth time rather than repeating
/// the same DropdownButtonFormField styling block four times over.
class _DarkDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF262019),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber[700]!),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item)),
              ))
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }
}

class _PerkCaption extends StatelessWidget {
  final String description;
  final String perkSummary;

  const _PerkCaption({required this.description, required this.perkSummary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: GoogleFonts.merriweather(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (perkSummary.isNotEmpty)
            Text(
              perkSummary,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Point-buy stat allocator. PROBLEM this replaces: attribute bonuses
/// used to come ONLY from the chosen Archetype - the player never
/// touched raw numbers themselves. SOLUTION: a small pool (12 points
/// over a base of 8 per stat, capped at 15 before archetype/background/
/// trait bonuses are added) the player distributes by hand, matching
/// the reference game's "Stat Distribution" step.
class _StatDistribution extends StatelessWidget {
  final Map<String, int> allocation;
  final List<String> order;
  final int pointsRemaining;
  final void Function(String key) onIncrement;
  final void Function(String key) onDecrement;

  const _StatDistribution({
    required this.allocation,
    required this.order,
    required this.pointsRemaining,
    required this.onIncrement,
    required this.onDecrement,
  });

  static const _labels = {
    'strength': 'STR',
    'dexterity': 'DEX',
    'intelligence': 'INT',
    'wisdom': 'WIS',
    'charisma': 'CHA',
    'constitution': 'CON',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF262019),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Points remaining',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$pointsRemaining',
                style: TextStyle(
                  color: pointsRemaining == 0 ? Colors.greenAccent : Colors.amber[300],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          for (final key in order)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _labels[key] ?? key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: Colors.white54,
                    onPressed: () => onDecrement(key),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${allocation[key]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: Colors.amber[300],
                    onPressed: () => onIncrement(key),
                  ),
                ],
              ),
            ),
        ],
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
