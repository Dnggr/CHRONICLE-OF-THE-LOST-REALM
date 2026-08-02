// ============================================================================
// BACKGROUNDS
// ----------------------------------------------------------------------------
// PROBLEM: the reference game's character creator (see the screenshot in
// this session) has more depth than our single Archetype pick - it layers
// Name, Gender, Portrait, Background, Trait, Stat Distribution, and
// Starting Equipment as SEPARATE choices. Archetype alone (Wanderer /
// Elf / Vampire / etc) was doing double duty as both "race/origin" AND
// "life story," which is exactly what Background is for in the
// reference. SOLUTION: Background is a new, independent layer - a small
// flavor + a single stat bonus + a starting gold nudge - picked
// alongside Archetype, not instead of it. A Vampire can also be an
// "Orphaned by War" background; the two compose.
//
// ENGINE NOTE: like Archetype, Background contributes its [id] to
// CharacterState.originTags (see CharacterState.fromCreationData), so
// scene JSON can gate on "origin.orphaned_by_war == true" exactly the
// same way it gates on "origin.royal == true" - no new condition syntax
// needed, this reuses the existing origin.<tag> pattern.
// ============================================================================

class Background {
  final String id;
  final String displayName;
  final String description;
  final String attributeKey;
  final int attributeBonus;
  final int goldBonus;

  const Background({
    required this.id,
    required this.displayName,
    required this.description,
    required this.attributeKey,
    required this.attributeBonus,
    this.goldBonus = 0,
  });

  String get perkSummary {
    final attrLabel = _label(attributeKey);
    final parts = ['+$attributeBonus $attrLabel'];
    if (goldBonus != 0) {
      parts.add('${goldBonus > 0 ? "+" : ""}$goldBonus Gold');
    }
    return parts.join(', ');
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

class Backgrounds {
  static const aspiringAdventurer = Background(
    id: 'aspiring_adventurer',
    displayName: 'Aspiring to be a Great Adventurer',
    description:
        'You grew up on stories of heroes and swore, one day, to become '
        'one yourself.',
    attributeKey: 'wisdom',
    attributeBonus: 1,
    goldBonus: 10,
  );

  static const runawayNoblesWard = Background(
    id: 'runaway_nobles_ward',
    displayName: "Runaway Noble's Ward",
    description:
        'Raised in a manor library more than a nursery, you slipped out '
        'the servants\' gate the night before your betrothal.',
    attributeKey: 'intelligence',
    attributeBonus: 1,
    goldBonus: 15,
  );

  static const orphanedByWar = Background(
    id: 'orphaned_by_war',
    displayName: 'Orphaned by War',
    description:
        'You don\'t remember the battle that took your family, only the '
        'years of moving camp to camp afterward.',
    attributeKey: 'constitution',
    attributeBonus: 1,
    goldBonus: 5,
  );

  static const merchantsApprentice = Background(
    id: 'merchants_apprentice',
    displayName: "Merchant's Apprentice",
    description:
        'You can read a room, a ledger, and a lie with equal ease - your '
        'old master taught you well before you outgrew the stall.',
    attributeKey: 'charisma',
    attributeBonus: 1,
    goldBonus: 20,
  );

  static const templeAcolyte = Background(
    id: 'temple_acolyte',
    displayName: 'Temple Acolyte',
    description:
        'Years of dawn prayers and quiet devotion left you patient in a '
        'way most people your age never learn.',
    attributeKey: 'wisdom',
    attributeBonus: 1,
    goldBonus: 5,
  );

  static const outlawsKin = Background(
    id: 'outlaws_kin',
    displayName: "Outlaw's Kin",
    description:
        'Your family\'s name still turns heads in the wrong taverns. You '
        'learned to move quickly and explain nothing.',
    attributeKey: 'dexterity',
    attributeBonus: 1,
    goldBonus: 0,
  );

  static const List<Background> all = [
    aspiringAdventurer,
    runawayNoblesWard,
    orphanedByWar,
    merchantsApprentice,
    templeAcolyte,
    outlawsKin,
  ];
}
