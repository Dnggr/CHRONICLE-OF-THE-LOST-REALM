/// A record of one dead character, permanently stored in WorldHistory.
class DeceasedHero {
  final String heroId;
  final String name;
  final String title;
  final String causeOfDeath;
  final int yearOfDeath;
  final int ageAtDeath;
  final String alignment;
  final String graveLocation;
  final List<String> relicsLeft;
  final List<String> majorCanonEvents;

  const DeceasedHero({
    required this.heroId,
    required this.name,
    required this.title,
    required this.causeOfDeath,
    required this.yearOfDeath,
    required this.ageAtDeath,
    required this.alignment,
    required this.graveLocation,
    required this.relicsLeft,
    required this.majorCanonEvents,
  });

  Map<String, dynamic> toJson() => {
        'heroId': heroId,
        'name': name,
        'title': title,
        'causeOfDeath': causeOfDeath,
        'yearOfDeath': yearOfDeath,
        'ageAtDeath': ageAtDeath,
        'alignment': alignment,
        'graveLocation': graveLocation,
        'relicsLeft': relicsLeft,
        'majorCanonEvents': majorCanonEvents,
      };

  factory DeceasedHero.fromJson(Map<String, dynamic> json) {
    return DeceasedHero(
      heroId: json['heroId'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      causeOfDeath: json['causeOfDeath'] as String,
      yearOfDeath: json['yearOfDeath'] as int,
      ageAtDeath: json['ageAtDeath'] as int,
      alignment: json['alignment'] as String,
      graveLocation: json['graveLocation'] as String,
      relicsLeft: (json['relicsLeft'] as List).cast<String>(),
      majorCanonEvents: (json['majorCanonEvents'] as List).cast<String>(),
    );
  }
}

/// The permanent, cross-playthrough world save. NEVER wiped on death or
/// new game - only ever appended to. This is what makes past runs feel
/// canon in future ones.
class WorldHistory {
  int currentYear;
  String monarchInPower;
  List<DeceasedHero> deceasedHeroes;
  Map<String, dynamic> worldFlags;

  WorldHistory({
    this.currentYear = 1200,
    this.monarchInPower = 'King Aldric III',
    List<DeceasedHero>? deceasedHeroes,
    Map<String, dynamic>? worldFlags,
  })  : deceasedHeroes = deceasedHeroes ?? [],
        worldFlags = worldFlags ?? {};

  DeceasedHero? get mostRecentHero =>
      deceasedHeroes.isEmpty ? null : deceasedHeroes.last;

  Map<String, dynamic> toJson() => {
        'currentYear': currentYear,
        'monarchInPower': monarchInPower,
        'deceasedHeroes': deceasedHeroes.map((h) => h.toJson()).toList(),
        'worldFlags': worldFlags,
      };

  factory WorldHistory.fromJson(Map<String, dynamic> json) {
    return WorldHistory(
      currentYear: json['currentYear'] as int,
      monarchInPower: json['monarchInPower'] as String,
      deceasedHeroes: (json['deceasedHeroes'] as List)
          .map((h) => DeceasedHero.fromJson(h as Map<String, dynamic>))
          .toList(),
      worldFlags: (json['worldFlags'] as Map).cast<String, dynamic>(),
    );
  }
}
