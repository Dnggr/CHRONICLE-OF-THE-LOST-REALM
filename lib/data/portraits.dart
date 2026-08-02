import 'package:flutter/material.dart';

/// PROBLEM: the reference game's Portrait field cycles through actual
/// illustrated character art, which we don't have (see the "no
/// illustrations bundled" note in README.md - the whole project runs
/// without final art on purpose). SOLUTION: a placeholder portrait
/// system using an icon + color pair, structured the same way real art
/// would be (a reorderable list you "reroll" through) so swapping in
/// real illustrated portraits later is a matter of changing
/// PortraitOption's rendering, not redesigning the selection flow. The
/// chosen [id] is stored on CharacterState.portraitId and read by
/// StatBar's avatar circle.
class PortraitOption {
  final String id;
  final IconData icon;
  final Color color;

  const PortraitOption({
    required this.id,
    required this.icon,
    required this.color,
  });
}

class Portraits {
  static const List<PortraitOption> all = [
    PortraitOption(id: 'p_swordsman', icon: Icons.person, color: Color(0xFF6B5B4B)),
    PortraitOption(id: 'p_archer', icon: Icons.person_outline, color: Color(0xFF4B6B5B)),
    PortraitOption(id: 'p_mage', icon: Icons.auto_awesome, color: Color(0xFF4B5B6B)),
    PortraitOption(id: 'p_rogue', icon: Icons.face_retouching_natural, color: Color(0xFF6B4B5B)),
    PortraitOption(id: 'p_noble', icon: Icons.emoji_events, color: Color(0xFF8B7355)),
    PortraitOption(id: 'p_beast', icon: Icons.pets, color: Color(0xFF5B4B3B)),
    PortraitOption(id: 'p_mystic', icon: Icons.nightlight_round, color: Color(0xFF3B3B5B)),
    PortraitOption(id: 'p_wanderer', icon: Icons.hiking, color: Color(0xFF5B6B4B)),
    PortraitOption(id: 'p_orc', icon: Icons.shield, color: Color(0xFF70533C)),
    PortraitOption(id: 'p_demon', icon: Icons.local_fire_department, color: Color(0xFF6A3A4A)),
  ];

  static PortraitOption byId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => all.first);
  }
}
