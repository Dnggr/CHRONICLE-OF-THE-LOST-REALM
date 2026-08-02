// ============================================================================
// TRAITS
// ----------------------------------------------------------------------------
// PROBLEM: the reference game's "Trait" field (e.g. "Magical - Use magic
// without equipment. Magic +1, INT +2") is a distinct mechanical hook
// from both race (Archetype) and life story (Background) - it reads
// more like a special talent/perk. SOLUTION: a third independent
// selection layer. Our engine has no separate "Magic" resource the way
// the reference does, so traits here grant bonuses using the SAME 6
// core stats as everything else (see DEVLOG.md Session 4 for why those
// are STR/DEX/INT/WIS/CHA/CON) rather than inventing a 7th stat just to
// mirror the reference exactly - keeps ConditionEvaluator and DiceRoller
// from needing to know about a stat that only Traits use.
// ============================================================================

class Trait {
  final String id;
  final String displayName;
  final String description;
  final Map<String, int> attributeBonuses;

  const Trait({
    required this.id,
    required this.displayName,
    required this.description,
    this.attributeBonuses = const {},
  });

  String get perkSummary {
    return attributeBonuses.entries
        .map((e) => '+${e.value} ${_label(e.key)}')
        .join(', ');
  }

  static String _label(String key) {
    switch (key) {
      case 'strength':
        return 'STR';
      case 'dexterity':
        return 'DEX';
      case 'intelligence':
        return 'INT';
      case 'wisdom':
        return 'WIS';
      case 'charisma':
        return 'CHA';
      case 'constitution':
        return 'CON';
      default:
        return key;
    }
  }
}

class Traits {
  static const magical = Trait(
    id: 'magical',
    displayName: 'Magical',
    description: 'A trace of the old power runs in you, untrained but real.',
    attributeBonuses: {'intelligence': 2},
  );

  static const brawler = Trait(
    id: 'brawler',
    displayName: 'Brawler',
    description: 'You have been in more fights than you\'ve lost.',
    attributeBonuses: {'strength': 2},
  );

  static const silverTongue = Trait(
    id: 'silver_tongue',
    displayName: 'Silver Tongue',
    description: 'People tend to believe you before they mean to.',
    attributeBonuses: {'charisma': 2},
  );

  static const ironWill = Trait(
    id: 'iron_will',
    displayName: 'Iron Will',
    description: 'Fear passes through you and finds nowhere to land.',
    attributeBonuses: {'wisdom': 2},
  );

  static const swift = Trait(
    id: 'swift',
    displayName: 'Swift',
    description: 'You are almost always the first one moving.',
    attributeBonuses: {'dexterity': 2},
  );

  static const hardy = Trait(
    id: 'hardy',
    displayName: 'Hardy',
    description: 'Cold, hunger, and sickness all seem to give up on you first.',
    attributeBonuses: {'constitution': 2},
  );

  static const List<Trait> all = [
    magical,
    brawler,
    silverTongue,
    ironWill,
    swift,
    hardy,
  ];
}
