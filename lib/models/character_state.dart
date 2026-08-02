import '../data/archetypes.dart';
import '../data/backgrounds.dart';
import '../data/equipment_kits.dart';
import '../data/traits.dart';

/// The active playthrough's character. This is wiped/reset on death -
/// permanent legacy data lives in WorldHistory instead.
///
/// CHANGE LOG (see /DEVLOG.md for the full story):
/// - Added [originTags] so the story can react to which Archetype the
///   player picked at creation (royal, elf, vampire, etc), not just to
///   raw attribute numbers. SOLUTION: originTags is a permanent,
///   un-earnable label set once at creation and read via
///   ConditionEvaluator's "origin.<tag> == true" pattern.
/// - Added [gender], [portraitId], [backgroundId], [traitId] this
///   session, to match the reference game's deeper character creator
///   (Name/Gender/Portrait/Background/Trait/Stat Distribution/Starting
///   Equipment, all as separate layers - see fromCreationData below).
///   Background and Trait also contribute their ids to [originTags],
///   the same way Archetype does, so scene JSON can react to them too
///   without any new condition syntax.
class CharacterState {
  String name;
  String gender;
  String portraitId;
  int age;
  int maxAge;

  /// strength, dexterity, intelligence, wisdom, charisma, constitution
  Map<String, int> attributes;

  int healthCurrent;
  int healthMax;
  int gold;
  List<String> inventory;
  List<String> statusEffects;

  /// Set once at character creation from Archetype + Background + Trait
  /// (each contributes its own id, plus any extraOriginTags). Never
  /// mutated during play - this is "what you were born as / became
  /// before the story started," not a flag you earn.
  List<String> originTags;

  /// Log of major choices taken this run, used both for the Journal
  /// screen and to decide what gets written into WorldHistory on death.
  List<String> runHistory;

  String currentSceneId;

  CharacterState({
    required this.name,
    this.gender = 'Unspecified',
    this.portraitId = 'p_wanderer',
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
              'strength': 10,
              'dexterity': 10,
              'intelligence': 10,
              'wisdom': 10,
              'charisma': 10,
              'constitution': 10,
            },
        inventory = inventory ?? [],
        statusEffects = statusEffects ?? [],
        originTags = originTags ?? [],
        runHistory = runHistory ?? [];

  /// Builds a brand-new character from every layer of the creation
  /// screen: name/gender/portrait, Archetype (race/origin), Background
  /// (life story), Trait (special talent), a player-allocated base stat
  /// spread (from Stat Distribution), and an EquipmentKit (class-style
  /// starting gear). This is the ONLY place any of those perks get
  /// applied - one source of truth instead of scattering "+gold if
  /// royal" logic across the UI and the engine.
  ///
  /// [baseAttributes] should already reflect the player's point-buy
  /// allocation (see CharacterCreationScreen's stat distribution step) -
  /// archetype/background/trait bonuses are added ON TOP of it here,
  /// not used to replace it.
  factory CharacterState.fromCreationData({
    required String name,
    required String gender,
    required String portraitId,
    required Archetype archetype,
    required Background background,
    required Trait trait,
    required EquipmentKit equipmentKit,
    required Map<String, int> baseAttributes,
  }) {
    final finalAttributes = Map<String, int>.from(baseAttributes);

    void applyBonus(String key, int bonus) {
      finalAttributes[key] = (finalAttributes[key] ?? 10) + bonus;
    }

    archetype.attributeBonuses.forEach(applyBonus);
    applyBonus(background.attributeKey, background.attributeBonus);
    trait.attributeBonuses.forEach(applyBonus);

    final gold = 10 +
        archetype.startingGoldBonus +
        background.goldBonus +
        equipmentKit.goldBonus;

    final inventory = <String>[
      ...archetype.startingInventory,
      ...equipmentKit.items,
    ];

    final originTags = <String>[
      archetype.id,
      ...archetype.extraOriginTags,
      background.id,
      trait.id,
    ];

    return CharacterState(
      name: name,
      gender: gender,
      portraitId: portraitId,
      attributes: finalAttributes,
      gold: gold,
      inventory: inventory,
      originTags: originTags,
      maxAge: archetype.maxAgeOverride ?? 65,
    );
  }

  bool get isDead => healthCurrent <= 0 || age >= maxAge;

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'portraitId': portraitId,
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
      // COMPATIBILITY NOTE: gender/portraitId were added after the first
      // save format shipped, same situation as originTags before them -
      // default rather than throw on an older save.
      gender: json['gender'] as String? ?? 'Unspecified',
      portraitId: json['portraitId'] as String? ?? 'p_wanderer',
      age: json['age'] as int,
      maxAge: json['maxAge'] as int,
      attributes: (json['attributes'] as Map).cast<String, int>(),
      healthCurrent: json['healthCurrent'] as int,
      healthMax: json['healthMax'] as int,
      gold: json['gold'] as int,
      inventory: (json['inventory'] as List).cast<String>(),
      statusEffects: (json['statusEffects'] as List).cast<String>(),
      originTags: (json['originTags'] as List?)?.cast<String>() ?? [],
      runHistory: (json['runHistory'] as List).cast<String>(),
      currentSceneId: json['currentSceneId'] as String,
    );
  }
}
