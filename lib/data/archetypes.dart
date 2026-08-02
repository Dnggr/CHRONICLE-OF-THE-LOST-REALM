// ============================================================================
// ARCHETYPES (playable origins)
// ----------------------------------------------------------------------------
// STORY DESIGN NOTE:
// Each archetype's perks are applied ONCE, at character creation, inside
// CharacterState.fromCreationData() (see character_state.dart). Origin itself
// is preserved for the rest of the run via CharacterState.originTags, which
// ConditionEvaluator reads through the "origin.<tag> == true" expression
// pattern (see condition_evaluator.dart).
//
// The Royal Heir archetype is deliberately tied to "House Aldric" - which
// matches WorldHistory's default monarchInPower ("King Aldric III") in
// world_history.dart. Playing a Royal Heir means you are, narratively,
// kin to the currently-reigning king.
//
// PROBLEM (this session): the original 5 custom stats (Might, Cunning,
// Lore, Presence, Endurance) didn't match the reference game (Life in
// Adventure), which the user confirmed uses a D&D-style 6-stat spread:
// Strength, Dexterity, Intelligence, Wisdom, Charisma, Constitution.
// SOLUTION: renamed to that exact 6-stat system throughout the codebase
// (CharacterState, StatBar, ConditionEvaluator usage, scene JSON). The
// old->new mapping used to redistribute existing archetype perks:
//   might -> strength, cunning -> dexterity, lore -> intelligence,
//   presence -> charisma, endurance -> constitution
// wisdom is new and wasn't part of the old 5, so it's used sparingly
// below (Wanderer, Elf) rather than retrofitted onto every archetype.
// ============================================================================

class Archetype {
  final String id;
  final String displayName;
  final String tagline;
  final String description;

  /// Added on top of the base 10 in every attribute. Can be negative
  /// (e.g. Dwarf trades Charisma for Strength/Constitution) - tradeoffs
  /// make the choice matter instead of every option being strictly
  /// better. Keys: strength, dexterity, intelligence, wisdom, charisma,
  /// constitution.
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

  /// Short "+2 STR, +1 CON" style summary for the selection card.
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
    attributeBonuses: {'constitution': 2, 'wisdom': 1},
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
    attributeBonuses: {'charisma': 2},
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
    attributeBonuses: {'intelligence': 1, 'charisma': 2},
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
    attributeBonuses: {'intelligence': 2, 'dexterity': 1, 'wisdom': 1},
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
    attributeBonuses: {'strength': 2, 'constitution': 2, 'charisma': -1},
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
    attributeBonuses: {'dexterity': 2, 'charisma': 2, 'constitution': -1},
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
    attributeBonuses: {'strength': 2, 'dexterity': 1},
    startingInventory: ['Notched Longsword', 'Boiled Leather Armor'],
    startingGoldBonus: -5,
    extraOriginTags: ['hunted'],
  );

  static const orc = Archetype(
    id: 'orc',
    displayName: 'Orc of the Ashbound Clans',
    tagline: 'An oath carried farther than any banner.',
    description:
        'You were raised among the Ashbound Clans, where a promise is spoken '
        'once and remembered by everyone who hears it. The lowland kingdoms '
        'mistake that discipline for savagery at their own cost.',
    attributeBonuses: {'strength': 2, 'constitution': 1, 'wisdom': 1},
    startingInventory: ['Ashbound Clan Token', 'Travel-worn Spear'],
    startingGoldBonus: 2,
    extraOriginTags: ['ashbound', 'clan_oath'],
  );

  static const demon = Archetype(
    id: 'demon',
    displayName: 'Demon-Bound',
    tagline: 'A borrowed body, a chosen name, a debt you refuse to become.',
    description:
        'Something infernal lives in your blood or behind your eyes. You are '
        'not a prophecy and not a weapon, whatever priests and summoners '
        'would prefer; every day you choose what kind of person bears that '
        'power.',
    attributeBonuses: {'charisma': 2, 'intelligence': 1, 'constitution': -1},
    startingInventory: ['Sealed Ember Pendant', 'Token of a Borrowed Name'],
    startingGoldBonus: -2,
    extraOriginTags: ['infernal', 'unnatural', 'distrusted_by_commonfolk'],
    maxAgeOverride: 180,
  );

  static const List<Archetype> all = [
    wanderer,
    civilian,
    royalHeir,
    elf,
    dwarf,
    vampire,
    mercenary,
    orc,
    demon,
  ];
}
