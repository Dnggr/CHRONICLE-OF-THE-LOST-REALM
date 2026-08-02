/// ============================================================================
/// WORLD EVENTS
/// ----------------------------------------------------------------------------
/// PROBLEM: the Story & Systems Bible (story_systems_bible.txt, section 3)
/// designed 13 world events as prose, but nothing made them referenceable
/// or discoverable in the engine - a scene writer had no single place to
/// look up "what stages does this event have" or "what world_flags key
/// does it use."
///
/// SOLUTION: this file is a structured CATALOG of every event's shape -
/// its world_flags key, its ordered stages, and a short description of
/// what it means. It's intentionally DATA, not behavior: nothing here
/// automatically advances a stage or fires triggers. Stage transitions
/// still happen the same way sun_temple_destroyed already works today -
/// a SceneChoice.effects entry like
/// { "world_flags.war_with_northern_reach": "active" }, written by hand
/// into whatever scene represents that turning point. This file exists
/// so every event's key/stage names are defined ONCE and referenced
/// consistently, instead of scene JSON authors re-typing string literals
/// that could typo out of sync with each other across dozens of files.
///
/// SCOPE NOTE: like npcs.dart, this gives every catalog event a real,
/// referenceable identity, but only ONE event (Harvest Failure) has
/// actual scene content behind it so far - see
/// assets/scenes/chapter1_harvest.json. The rest are ready to write
/// scenes against whenever you get to them; the catalog entry tells you
/// exactly which world_flags key and stage strings to use so the scene
/// JSON stays consistent with this file.
/// ============================================================================

class WorldEvent {
  final String id;
  final String displayName;

  /// The world_flags key this event's current stage is stored under,
  /// e.g. "war_with_northern_reach". Scene JSON checks it exactly like
  /// any other flags.<key> == 'stage_name' condition.
  final String flagKey;

  /// Ordered stages, e.g. ['brewing', 'skirmishes', 'active']. The LAST
  /// entries are typically multiple possible outcomes rather than a
  /// single next stage - see [outcomes].
  final List<String> stages;

  /// Possible terminal outcome values (mutually exclusive) - stored
  /// under a SEPARATE flag, conventionally "<flagKey>_outcome", so the
  /// "currently active" stage and "how it ended" don't collide in one
  /// flag once the event resolves.
  final List<String> outcomes;

  final String description;
  final String legacyTieIn;

  const WorldEvent({
    required this.id,
    required this.displayName,
    required this.flagKey,
    required this.stages,
    required this.outcomes,
    required this.description,
    required this.legacyTieIn,
  });

  String get outcomeFlagKey => '${flagKey}_outcome';
}

class WorldEvents {
  static const warWithNorthernReach = WorldEvent(
    id: 'war_with_northern_reach',
    displayName: 'War with the Northern Reach',
    flagKey: 'war_with_northern_reach',
    stages: ['brewing', 'skirmishes', 'active'],
    outcomes: ['aldric_victory', 'northern_victory', 'stalemate_treaty'],
    description:
        'Triggered by world.currentYear crossing a threshold, or by the '
        'player insulting/attacking a Northern Reach envoy. Ser Aldous '
        "Fenn is deployed and can die in 'active' stage without a treaty "
        "path secured.",
    legacyTieIn:
        "If a prior playthrough's DeceasedHero has a destabilizing canon "
        "event (e.g. \"Assassinated Duke Vane\"), this starts already at "
        "'skirmishes', not 'brewing'.",
  );

  static const rebellionOfSaltRoad = WorldEvent(
    id: 'rebellion_of_salt_road',
    displayName: 'The Rebellion of the Salt Road',
    flagKey: 'rebellion_salt_road',
    stages: ['unrest', 'organized', 'uprising'],
    outcomes: ['crushed', 'concessions_won', 'regime_change'],
    description:
        'Triggered by repeated player choices siding against merchant '
        'guilds, or a fixed late-game trigger if ignored. Yeva Solt and '
        'Petra Voss may end up on opposite sides.',
    legacyTieIn:
        "If a past hero died as an executed outlaw, rebellion sentiment "
        "starts higher - the realm remembers martyrs.",
  );

  static const dragonOfSkellRidge = WorldEvent(
    id: 'dragon_of_skell_ridge',
    displayName: 'The Dragon of Skell Ridge',
    flagKey: 'dragon_of_skell',
    stages: ['sightings', 'livestock_raids', 'territorial'],
    outcomes: ['slain', 'bound', 'appeased', 'fled'],
    description:
        'A fixed mid-game story beat, or accelerated if a past '
        "playthrough's majorCanonEvents mentions the dragon by name. "
        'Elf-origin players can use old wards; Dwarf-origin players can '
        'approach via tunnel networks.',
    legacyTieIn:
        "Strongest callback in the catalog - literally scales in "
        "difficulty based on a past character's failure against it.",
  );

  static const sunTempleSchism = WorldEvent(
    id: 'sun_temple_schism',
    displayName: 'The Sun Temple Schism',
    flagKey: 'sun_temple_schism',
    stages: ['mourning', 'factional_split'],
    outcomes: ['new_orthodoxy', 'zealot_uprising', 'faith_abandoned'],
    description:
        'ONLY exists in worlds where world_flags.sun_temple_destroyed is '
        'true. Inquisitor Rane gains or loses institutional backing '
        "depending on this event's outcome.",
    legacyTieIn:
        'Exists ONLY because of a prior run\'s choice - the strongest '
        "demonstration of the Legacy Engine's promise so far.",
  );

  static const plagueOfHollowReaches = WorldEvent(
    id: 'plague_of_hollow_reaches',
    displayName: 'The Plague Out of the Hollow Reaches',
    flagKey: 'plague_hollow_reaches',
    stages: ['rumors', 'outbreak', 'quarantine'],
    outcomes: ['contained', 'spreads_to_capital', 'mysteriously_ends'],
    description:
        'Time-based (later game years), or triggered by looting a '
        'cursed ruin without precaution. Old Hendrik is a strong '
        'candidate to die here if unaided.',
    legacyTieIn:
        'None required - a good "the world still moves" event even on '
        "a player's first-ever run.",
  );

  static const successionCrisis = WorldEvent(
    id: 'succession_crisis',
    displayName: 'Succession Crisis',
    flagKey: 'succession_crisis',
    stages: ['mourning', 'claims_contested'],
    outcomes: ['aldric_continues', 'marrow_ascends', 'regency_council', 'civil_war'],
    description:
        "A fixed story beat, or accelerated if Lady Ysolde Marrow's "
        'plot succeeds. Highest-stakes event for Royal Heir-origin '
        'players specifically.',
    legacyTieIn:
        'If a past Royal Heir died without securing succession, this '
        'triggers automatically and earlier next time.',
  );

  static const foreignInvasion = WorldEvent(
    id: 'foreign_invasion',
    displayName: 'Foreign Invasion from Across the Salt Sea',
    flagKey: 'foreign_invasion',
    stages: ['raids', 'beachhead'],
    outcomes: ['repelled', 'partial_occupation', 'full_invasion'],
    description:
        'Very late-game, time-based, mostly independent of player '
        'choice on purpose. Can unify factions from other events into '
        'common cause.',
    legacyTieIn:
        'Severity scales with how fractured the realm currently is - '
        'active war + active rebellion + schism means weaker resistance.',
  );

  // --- Minor/atmosphere events (briefly catalogued, per the bible) ---
  static const counterfeitCoinCrisis = WorldEvent(
    id: 'counterfeit_coin_crisis',
    displayName: 'The Counterfeit Coin Crisis',
    flagKey: 'counterfeit_coin_crisis',
    stages: ['emerging', 'active'],
    outcomes: ['resolved', 'currency_devalued'],
    description: 'Economic event, guild-focused, devalues gold and shifts prices world_flags-wide.',
    legacyTieIn: 'None specified.',
  );

  static const undeadStirring = WorldEvent(
    id: 'undead_stirring',
    displayName: 'The Undead Stirring at the Old Battlefield',
    flagKey: 'undead_stirring',
    stages: ['omens', 'active'],
    outcomes: ['put_to_rest', 'spreads'],
    description:
        'Horror-flavored; can raise a past DeceasedHero as an '
        'antagonist if their causeOfDeath was violent.',
    legacyTieIn: "Direct DeceasedHero reanimation hook - see this event's description.",
  );

  static const royalWeddingOrFuneral = WorldEvent(
    id: 'royal_wedding_or_funeral',
    displayName: 'The Royal Wedding (or Funeral)',
    flagKey: 'royal_court_gathering',
    stages: ['announced', 'underway'],
    outcomes: ['concluded'],
    description: 'A court-politics set-piece - good "everyone in one place" scene.',
    legacyTieIn: 'None specified.',
  );

  static const cometOmenYear = WorldEvent(
    id: 'comet_omen_year',
    displayName: 'The Comet / Omen Year',
    flagKey: 'omen_year',
    stages: ['active'],
    outcomes: ['passed'],
    description: 'Superstition-driven atmosphere event; no hard mechanical outcome.',
    legacyTieIn: 'None specified.',
  );

  static const mercenaryCompanyWar = WorldEvent(
    id: 'mercenary_company_war',
    displayName: 'The Mercenary Company War',
    flagKey: 'mercenary_company_war',
    stages: ['brewing', 'active'],
    outcomes: ['players_company_wins', 'rival_company_wins', 'both_destroyed'],
    description:
        'Small-scale counterpart to the Northern Reach war - the '
        "player's old company (if Mercenary-origin) may be involved.",
    legacyTieIn: 'None specified.',
  );

  static const harvestFailure = WorldEvent(
    id: 'harvest_failure',
    displayName: 'The Harvest Failure',
    flagKey: 'harvest_failure',
    stages: ['warning_signs', 'active', 'desperate'],
    outcomes: ['resolved', 'famine', 'quietly_endured'],
    description:
        "Slow-burn economic/survival event, strongest tie to Civilian "
        'content. FULLY IMPLEMENTED - see assets/scenes/chapter1_harvest.json '
        "and Mira Talbot's arc, which doubles as the bible's own worked "
        'mini-example (section 6).',
    legacyTieIn: 'None specified.',
  );

  static const List<WorldEvent> all = [
    warWithNorthernReach,
    rebellionOfSaltRoad,
    dragonOfSkellRidge,
    sunTempleSchism,
    plagueOfHollowReaches,
    successionCrisis,
    foreignInvasion,
    counterfeitCoinCrisis,
    undeadStirring,
    royalWeddingOrFuneral,
    cometOmenYear,
    mercenaryCompanyWar,
    harvestFailure,
  ];

  static WorldEvent? byId(String id) {
    for (final event in all) {
      if (event.id == id) return event;
    }
    return null;
  }
}
