/// The active playthrough's character. This is wiped/reset on death -
/// permanent legacy data lives in WorldHistory instead.
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
        runHistory = runHistory ?? [];

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
      runHistory: (json['runHistory'] as List).cast<String>(),
      currentSceneId: json['currentSceneId'] as String,
    );
  }
}
