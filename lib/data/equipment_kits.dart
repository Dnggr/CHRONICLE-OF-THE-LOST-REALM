/// PROBLEM: Archetype already grants race-flavor starting gear (e.g. an
/// Elf gets a Heirloom Longbow), but the reference game separately lets
/// you pick a class-style loadout ("Starting Equipment: Wizard") on top
/// of your race. SOLUTION: EquipmentKit is independent of Archetype -
/// its items are ADDED to whatever the Archetype already grants (see
/// CharacterState.fromCreationData), so a Dwarf Wizard and an Elf
/// Wizard both get the wizard's gear, plus their own race's gear.
class EquipmentKit {
  final String id;
  final String displayName;
  final String description;
  final List<String> items;
  final int goldBonus;

  const EquipmentKit({
    required this.id,
    required this.displayName,
    required this.description,
    required this.items,
    this.goldBonus = 0,
  });
}

class EquipmentKits {
  static const wizard = EquipmentKit(
    id: 'wizard',
    displayName: 'Wizard',
    description: 'Trained in the old theory, light on the practice.',
    items: ["Apprentice's Spellbook", 'Wooden Wand'],
  );

  static const warrior = EquipmentKit(
    id: 'warrior',
    displayName: 'Warrior',
    description: 'You\'d rather solve it with steel.',
    items: ['Iron Sword', 'Wooden Shield'],
  );

  static const rogue = EquipmentKit(
    id: 'rogue',
    displayName: 'Rogue',
    description: 'Quiet feet, quicker hands.',
    items: ['Twin Daggers', 'Lockpicks'],
  );

  static const ranger = EquipmentKit(
    id: 'ranger',
    displayName: 'Ranger',
    description: 'More comfortable under open sky than a roof.',
    items: ['Hunting Bow', 'Quiver of Arrows'],
  );

  static const pilgrim = EquipmentKit(
    id: 'pilgrim',
    displayName: 'Pilgrim',
    description: 'You travel light, and trust to something larger.',
    items: ["Traveler's Staff", 'Holy Symbol'],
    goldBonus: 5,
  );

  static const List<EquipmentKit> all = [
    wizard,
    warrior,
    rogue,
    ranger,
    pilgrim,
  ];
}
