import '../data/archetypes.dart';

/// The active playthrough's character. This is wiped/reset on death -
/// permanent legacy data lives in WorldHistory instead.
///
/// CHANGE LOG (see /DEVLOG.md for the full story):
/// - Added [originTags] so the story can react to which Archetype the
///   player picked at creation (royal, elf, vampire, etc), not just to
///   raw attribute numbers. PROBLEM this solves: attribute bonuses alone
///   (e.g. Royal Heir having +2 Presence) are indistinguishable from any
///   other build that happens to roll high Presence - there was no way
///   for scene JSON to say "only if you ARE a vampire" vs "only if your
///   Cunning is high enough to convincingly fake being unsettling."
///   SOLUTION: originTags is a permanent, un-earnable label set once at
///   creation and read via ConditionEvaluator's "origin.<tag> == true"
///   pattern (see condition_evaluator.dart).
class CharacterState {
  String name;
  int age;
  int maxAge;

  /// might, cunning, lore, presence, endurance
  Map<String, int> attributes;

  int healthCurrent;
  int healthMax;
  int gold;
  List<String> inventory;
  List<String> statusEffects;

  /// Set once at character creation from the chosen Archetype (its id,
  /// plus any extraOriginTags - e.g. picking Royal Heir gives
  /// ["royal_heir", "royal", "recognized_by_guards"]). Never mutated
  /// during play - this is "what you were born as," not a flag you earn.
  List<String> originTags;

  /// Log of major choices taken this run, used both for the Journal
  /// screen and to decide what gets written into WorldHistory on death.
  List<String> runHistory;

  String currentSceneId;

  CharacterState({
    required this.name,
    this.age = 18,
    this.maxAge = 65,
    Map<String, int>? attributes,
    this.healthCurrent = 100,
    this.healthMax = 100,
    this.gold = 10,
    List<String>? inventory,
    List<String>? statusEffects,
    List<String>? originTags,
    List<String>? runHistory,
    this.currentSceneId = 'prologue_start',
  })  : attributes = attributes ??
            {
              'might': 10,
              'cunning': 10,
              'lore': 10,
              'presence': 10,
              'endurance': 10,
            },
        inventory = inventory ?? [],
        statusEffects = statusEffects ?? [],
        originTags = originTags ?? [],
        runHistory = runHistory ?? [];

  /// Builds a brand-new character from a player-chosen name + Archetype.
  /// This is the ONLY place archetype perks get applied - attribute
  /// bonuses, starting gear/gold, and origin tags all flow from here so
  /// there's a single source of truth instead of scattering "if royal
  /// then +gold" logic across the UI and the engine.
  factory CharacterState.fromArchetype({
    required String name,
    required Archetype archetype,
  }) {
    final baseAttributes = {
      'might': 10,
      'cunning': 10,
      'lore': 10,
      'presence': 10,
      'endurance': 10,
    };
    archetype.attributeBonuses.forEach((key, bonus) {
      baseAttributes[key] = (baseAttributes[key] ?? 10) + bonus;
    });

    return CharacterState(
      name: name,
      attributes: baseAttributes,
      gold: 10 + archetype.startingGoldBonus,
      inventory: List<String>.from(archetype.startingInventory),
      originTags: [archetype.id, ...archetype.extraOriginTags],
      maxAge: archetype.maxAgeOverride ?? 65,
    );
  }

  bool get isDead => healthCurrent <= 0 || age >= maxAge;

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'maxAge': maxAge,
        'attributes': attributes,
        'healthCurrent': healthCurrent,
        'healthMax': healthMax,
        'gold': gold,
        'inventory': inventory,
        'statusEffects': statusEffects,
        'originTags': originTags,
        'runHistory': runHistory,
        'currentSceneId': currentSceneId,
      };

  factory CharacterState.fromJson(Map<String, dynamic> json) {
    return CharacterState(
      name: json['name'] as String,
      age: json['age'] as int,
      maxAge: json['maxAge'] as int,
      attributes: (json['attributes'] as Map).cast<String, int>(),
      healthCurrent: json['healthCurrent'] as int,
      healthMax: json['healthMax'] as int,
      gold: json['gold'] as int,
      inventory: (json['inventory'] as List).cast<String>(),
      statusEffects: (json['statusEffects'] as List).cast<String>(),
      // OPTIMIZATION/COMPATIBILITY NOTE: originTags was added after the
      // first save format shipped. Default to [] instead of throwing if
      // an old save (written before this field existed) doesn't have it,
      // so existing saves on your phone don't break when you update.
      originTags: (json['originTags'] as List?)?.cast<String>() ?? [],
      runHistory: (json['runHistory'] as List).cast<String>(),
      currentSceneId: json['currentSceneId'] as String,
    );
  }
}
