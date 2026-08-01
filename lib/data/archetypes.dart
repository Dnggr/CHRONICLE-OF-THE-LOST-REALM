// ============================================================================
// ARCHETYPES (playable origins)
// ----------------------------------------------------------------------------
// STORY DESIGN NOTE:
// The original build plan (see the .txt plan doc) only specced a single
// generic "adventurer" start, like Life in Adventure's default. The user
// asked for a proper origin-select screen instead - Wanderer, Civilian,
// royalty, and a few fantasy races - each with mechanical perks (stat
// bonuses, starting gear/gold) AND narrative hooks (origin tags that scene
// JSON can check, so the story actually reacts to who you picked, not just
// your stat sheet).
//
// The Royal Heir archetype is deliberately tied to "House Aldric" - which
// matches WorldHistory's default monarchInPower ("King Aldric III") in
// world_history.dart. That's intentional continuity: if you play a Royal
// Heir, you are, narratively, kin to the currently-reigning king. Keep this
// in sync if you ever rename the default monarch.
//
// ENGINE NOTE:
// Each archetype's perks are applied ONCE, at character creation, inside
// CharacterState.fromArchetype() (see character_state.dart). Origin itself
// is preserved for the rest of the run via CharacterState.originTags, which
// ConditionEvaluator reads through the "origin.<tag> == true" expression
// pattern (see condition_evaluator.dart) - that's what lets scene JSON gate
// choices/text on "did the player pick Vampire", not just on stats.
// ============================================================================

class Archetype {
  final String id;
  final String displayName;
  final String tagline;
  final String description;

  /// Added on top of the base 10 in every attribute. Can be negative
  /// (e.g. Dwarf trades Presence for Might/Endurance) - tradeoffs make
  /// the choice matter instead of every option being strictly better.
  final Map<String, int> attributeBonuses;

  final List<String> startingInventory;
  final int startingGoldBonus;

  /// Written into CharacterState.originTags on creation. Scene JSON
  /// checks these via "origin.<tag> == true". Always includes [id]
  /// automatically (see CharacterState.fromArchetype) - only list EXTRA
  /// tags here beyond the archetype's own id.
  final List<String> extraOriginTags;

  final int? maxAgeOverride;

  const Archetype({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.description,
    this.attributeBonuses = const {},
    this.startingInventory = const [],
    this.startingGoldBonus = 0,
    this.extraOriginTags = const [],
    this.maxAgeOverride,
  });

  /// Short "+2 Might, +1 Endurance" style summary for the selection card.
  String get perkSummary {
    final parts = attributeBonuses.entries
        .where((e) => e.value != 0)
        .map((e) => '${e.value > 0 ? "+" : ""}${e.value} ${_label(e.key)}')
        .toList();
    if (startingGoldBonus != 0) {
      parts.add('${startingGoldBonus > 0 ? "+" : ""}$startingGoldBonus Gold');
    }
    return parts.join(', ');
  }

  static String _label(String attrKey) {
    switch (attrKey) {
      case 'might':
        return 'Might';
      case 'cunning':
        return 'Cunning';
      case 'lore':
        return 'Lore';
      case 'presence':
        return 'Presence';
      case 'endurance':
        return 'Endurance';
      default:
        return attrKey;
    }
  }
}

/// The full roster of playable origins. Add new ones here - nothing else
/// needs to change, CharacterCreationScreen renders this list directly.
class Archetypes {
  static const wanderer = Archetype(
    id: 'wanderer',
    displayName: 'Wanderer',
    tagline: 'No home, no ties, no one waiting for you.',
    description:
        'You left the road behind you long ago. Hardship taught you to '
        'keep moving and keep quiet.',
    attributeBonuses: {'endurance': 2},
    startingInventory: ['Traveler\'s Cloak', 'Worn Waterskin'],
    startingGoldBonus: 0,
  );

  static const civilian = Archetype(
    id: 'civilian',
    displayName: 'Civilian',
    tagline: 'A farmer\'s child, chasing a hero\'s dream.',
    description:
        'You grew up among ordinary people, and they still trust you like '
        'one of their own - that counts for more than a blade, sometimes.',
    attributeBonuses: {'presence': 2},
    startingInventory: ['Family Heirloom Ring'],
    startingGoldBonus: 5,
  );

  static const royalHeir = Archetype(
    id: 'royal_heir',
    displayName: 'Heir of House Aldric',
    tagline: 'Born to the throne. Burdened by it, too.',
    description:
        'You are blood of the ruling house. Doors open for you that stay '
        'shut to others - but so do old grudges, and every guard in the '
        'realm knows your face.',
    attributeBonuses: {'lore': 1, 'presence': 2},
    startingInventory: ['Signet Ring of House Aldric', 'Fine Steel Dagger'],
    startingGoldBonus: 25,
    extraOriginTags: ['royal', 'recognized_by_guards'],
  );

  static const elf = Archetype(
    id: 'elf',
    displayName: 'Elf',
    tagline: 'Centuries of memory behind quiet eyes.',
    description:
        'You have watched empires rise and fall before. Little in this '
        'age surprises you, and you have had a long time to master the bow '
        'and the old tongues.',
    attributeBonuses: {'lore': 2, 'cunning': 1},
    startingInventory: ['Heirloom Longbow', 'Pressed Silverleaf'],
    maxAgeOverride: 200,
    extraOriginTags: ['longlived'],
  );

  static const dwarf = Archetype(
    id: 'dwarf',
    displayName: 'Dwarf',
    tagline: 'Stone-stubborn, iron-armed, plain-spoken.',
    description:
        'You were raised under the mountain, where a handshake means more '
        'than a smile. You hit hard and you outlast almost anyone.',
    attributeBonuses: {'might': 2, 'endurance': 2, 'presence': -1},
    startingInventory: ['Dwarven War-Axe'],
    startingGoldBonus: 10,
  );

  static const vampire = Archetype(
    id: 'vampire',
    displayName: 'Vampire',
    tagline: 'Something ancient wears a human face.',
    description:
        'Cursed or blessed, depending who you ask, with unnatural charm '
        'and an unnatural hunger. Common folk feel it, even if they '
        'couldn\'t say why they\'re uneasy around you.',
    attributeBonuses: {'cunning': 2, 'presence': 2, 'endurance': -1},
    startingInventory: ['Cold Iron Ring (sealed)'],
    extraOriginTags: ['unnatural', 'distrusted_by_commonfolk'],
  );

  static const mercenary = Archetype(
    id: 'mercenary',
    displayName: 'Exiled Mercenary',
    tagline: 'Sold your sword until your last company sold you out.',
    description:
        'You have killed for coin on three different battlefields, and '
        'you\'d rather not talk about why your old company wants you dead.',
    attributeBonuses: {'might': 2, 'cunning': 1},
    startingInventory: ['Notched Longsword', 'Boiled Leather Armor'],
    startingGoldBonus: -5,
    extraOriginTags: ['hunted'],
  );

  static const List<Archetype> all = [
    wanderer,
    civilian,
    royalHeir,
    elf,
    dwarf,
    vampire,
    mercenary,
  ];
}
