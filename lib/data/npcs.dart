/// ============================================================================
/// SIGNATURE NPCs
/// ----------------------------------------------------------------------------
/// PROBLEM: the Story & Systems Bible (story_systems_bible.txt) designed
/// 42 named NPCs - 6 roles x 7 origins - as prose character sheets, but
/// nothing in the engine could reference them by id, look up which NPC
/// belongs to which origin, or check their role/status programmatically.
/// SOLUTION: this file is the structured, in-engine counterpart to the
/// bible's section 2.3 - one Npc object per character, keyed by the SAME
/// npc_id convention CharacterState.npcTrust/npcStatus and
/// ConditionEvaluator's "npc.<id>.trust"/"npc.<id>.status" patterns use.
///
/// SCOPE NOTE: this file gives every Signature NPC a real, referenceable
/// identity in the engine (id, role, origin link, personality summary).
/// It does NOT mean all 42 have full scene content written yet - see
/// assets/scenes/chapter1_harvest.json for the one fully-implemented
/// example (Mira Talbot's arc), which is also the bible's own "worked
/// mini-example" from section 6. Wiring the rest into real scenes is
/// content work, not engine work - the data below is what that content
/// work would reference (npc_id, condition keys, etc), so writing a new
/// NPC's scenes never requires touching this file's structure, only
/// adding scene JSON that reads it.
/// ============================================================================

enum NpcRole { ally, enemy, merchant, mentor, rival, wildcard }

class Npc {
  final String id;
  final String displayName;
  final NpcRole role;

  /// Which Archetype id this NPC is the "corresponding NPC" for, per the
  /// bible's per-origin structure. Null for background/unaffiliated NPCs
  /// (the bible's generation-framework NPCs, not modeled individually
  /// here - see the bible's section 2.4 for how those are authored).
  final String? linkedOriginId;

  final String coreTrait;
  final String motivation;
  final String secretOrFlaw;
  final String voicePattern;
  final String storyHook;

  const Npc({
    required this.id,
    required this.displayName,
    required this.role,
    required this.linkedOriginId,
    required this.coreTrait,
    required this.motivation,
    required this.secretOrFlaw,
    required this.voicePattern,
    required this.storyHook,
  });
}

class Npcs {
  // --- Wanderer-linked ---
  static const corwinAshe = Npc(
    id: 'corwin_ashe',
    displayName: 'Corwin Ashe',
    role: NpcRole.ally,
    linkedOriginId: 'wanderer',
    coreTrait: 'Relentlessly practical',
    motivation: 'Find the sister he lost track of three winters ago',
    secretOrFlaw: "Already knows his sister is dead and hasn't admitted it",
    voicePattern: 'Never uses a metaphor when a plain sentence will do',
    storyHook:
        'Traveling companion; arc resolves only if the player helps him '
        'find (and bury) her - skipping it leaves him permanently '
        'withdrawn for the rest of the run.',
  );

  static const tollkeeper = Npc(
    id: 'the_tollkeeper',
    displayName: 'The Tollkeeper',
    role: NpcRole.enemy,
    linkedOriginId: 'wanderer',
    coreTrait: 'Performs politeness as a weapon',
    motivation: 'Total control of a stretch of the Old Salt Road',
    secretOrFlaw:
        'A fired Crownlands tax officer running the same racket '
        'unofficially now',
    voicePattern: 'Formal, archaic phrasing even when threatening you',
    storyHook:
        'Recurring antagonist for road-heavy Wanderer runs; escalates '
        'from "toll" to "hostage" if ignored too many times.',
  );

  static const oldFerrick = Npc(
    id: 'old_ferrick',
    displayName: 'Old Ferrick',
    role: NpcRole.merchant,
    linkedOriginId: 'wanderer',
    coreTrait: 'Sells anything, asks nothing',
    motivation: 'Enough coin to stop moving and open a real shop',
    secretOrFlaw: "Half his stock is stolen from travelers he's \"helped\"",
    voicePattern: "Talks in prices (\"that'll cost you a story, not just coin\")",
    storyHook: 'Great prices, but trusting him to hold anything is a trap.',
  );

  static const saoirseBellwether = Npc(
    id: 'saoirse_bellwether',
    displayName: 'Saoirse Bellwether',
    role: NpcRole.mentor,
    linkedOriginId: 'wanderer',
    coreTrait: 'Teaches through discomfort',
    motivation: "See if this Wanderer is different from the ones who gave up",
    secretOrFlaw: "Was once a Royal Heir's bodyguard and abandoned that life",
    voicePattern: 'Answers questions with harder questions',
    storyHook:
        'Teaches reading weather/danger signs; also a cross-origin hook '
        'for Royal Heir players.',
  );

  static const dennHalloway = Npc(
    id: 'denn_halloway',
    displayName: 'Denn Halloway',
    role: NpcRole.rival,
    linkedOriginId: 'wanderer',
    coreTrait: 'Competitive about everything',
    motivation: 'Be remembered as the greatest road-walker in the Realm',
    secretOrFlaw:
        "Deeply lonely; picks rivalries because they're the only "
        'relationships he knows how to sustain',
    voicePattern: 'Turns every conversation into a bet',
    storyHook:
        'Recurring challenger; losing repeatedly costs minor reputation, '
        'befriending him instead is a hidden resolution.',
  );

  static const piebaldFool = Npc(
    id: 'piebald_fool',
    displayName: 'The Piebald Fool',
    role: NpcRole.wildcard,
    linkedOriginId: 'wanderer',
    coreTrait: 'Unreadable, possibly touched by something otherworldly',
    motivation: 'Unclear, possibly nothing human',
    secretOrFlaw: 'Seems to know about world events before they happen',
    voicePattern: 'Rhymes, sometimes mid-sentence',
    storyHook:
        'Shows up near major world-event trigger points; drops '
        'information the player can use or ignore.',
  );

  // --- Civilian-linked ---
  static const miraTalbot = Npc(
    id: 'mira_talbot',
    displayName: 'Mira Talbot',
    role: NpcRole.ally,
    linkedOriginId: 'civilian',
    coreTrait: 'Fiercely loyal once trust is earned',
    motivation: "Keep her family's farm through a bad harvest year",
    secretOrFlaw:
        'Has been quietly stealing from a neighbor to make ends meet, '
        'and is ashamed of it',
    voicePattern: 'Plainspoken, dry humor',
    storyHook:
        'A small-scale Redemption Route in miniature; her Harvest '
        'Failure arc is fully implemented - see chapter1_harvest.json.',
  );

  static const bailiffReyes = Npc(
    id: 'bailiff_reyes',
    displayName: 'Bailiff Corin Reyes',
    role: NpcRole.enemy,
    linkedOriginId: 'civilian',
    coreTrait: 'Believes rules ARE morality',
    motivation: 'Enforce order, full stop, regardless of context',
    secretOrFlaw:
        'Enforces the law harshest on people who remind him of his own '
        'poor upbringing',
    voicePattern: 'Quotes actual statutes at people',
    storyHook:
        'Not irredeemable - has a late redemption opening if the player '
        'repeatedly demonstrates mercy was the right call.',
  );

  static const yevaSolt = Npc(
    id: 'yeva_solt',
    displayName: 'Guildmistress Yeva Solt',
    role: NpcRole.merchant,
    linkedOriginId: 'civilian',
    coreTrait: 'Shrewd, never unfriendly',
    motivation: "Expand her trade guild's influence into the Capital",
    secretOrFlaw:
        "Quietly funds the local orphanage and would be furious if "
        'anyone found out and thanked her',
    voicePattern: '"And what\'s in it for YOU?" before agreeing to anything',
    storyHook:
        'Gates better prices behind small favors, building toward a real '
        'business partnership late-game.',
  );

  static const oldHendrik = Npc(
    id: 'old_hendrik',
    displayName: 'Old Hendrik',
    role: NpcRole.mentor,
    linkedOriginId: 'civilian',
    coreTrait: 'Stubbornly optimistic',
    motivation: 'Pass on the trade before he dies',
    secretOrFlaw: "Dying of something he hasn't told anyone",
    voicePattern: 'Tells the same three stories, slightly differently, every time',
    storyHook:
        'The player can be present for his death - a non-combat use of '
        'the "someone dies" beat.',
  );

  static const petraVoss = Npc(
    id: 'petra_voss',
    displayName: 'Petra Voss',
    role: NpcRole.rival,
    linkedOriginId: 'civilian',
    coreTrait: 'Ambitious, hides it under modesty',
    motivation: "The Guildmistress's position, eventually",
    secretOrFlaw: 'Is better at the job than Yeva Solt and knows it',
    voicePattern: 'Self-deprecating in a way that is clearly strategic',
    storyHook: 'A rivalry resolved socially/economically, not through violence.',
  );

  static const tamsinBellRinger = Npc(
    id: 'tamsin_bell_ringer',
    displayName: 'Tamsin the Bell-Ringer',
    role: NpcRole.wildcard,
    linkedOriginId: 'civilian',
    coreTrait: 'Town gossip, weaponized',
    motivation: 'To matter, to be the one who KNOWS things',
    secretOrFlaw:
        "Half of what she says is true and she genuinely can't remember "
        'which half',
    voicePattern: '"You didn\'t hear this from me"',
    storyHook: 'Information broker, sometimes right, sometimes catastrophically wrong.',
  );

  // --- Royal Heir-linked ---
  static const serAldousFenn = Npc(
    id: 'ser_aldous_fenn',
    displayName: 'Ser Aldous Fenn',
    role: NpcRole.ally,
    linkedOriginId: 'royal_heir',
    coreTrait: 'Old-fashioned loyalty',
    motivation: "Protect House Aldric's line even from itself",
    secretOrFlaw: 'Privately believes the king is unfit',
    voicePattern: 'Formal, clipped',
    storyHook:
        "The player's most reliable protector; loyalty tested hardest by "
        'the Revenge or Power routes against the crown.',
  );

  static const ladyYsoldeMarrow = Npc(
    id: 'lady_ysolde_marrow',
    displayName: 'Lady Ysolde Marrow',
    role: NpcRole.enemy,
    linkedOriginId: 'royal_heir',
    coreTrait: 'Patient, plays decades-long games',
    motivation: 'House Marrow on the throne instead of House Aldric',
    secretOrFlaw: 'Has a legitimate, buried claim to the throne herself',
    voicePattern: 'Compliments that land like threats',
    storyHook:
        "Primary long-game antagonist; possible late reveal tying her to "
        "the Sun Temple's destruction if that flag is set.",
  );

  static const quartermasterCray = Npc(
    id: 'quartermaster_cray',
    displayName: 'Quartermaster Bellamy Cray',
    role: NpcRole.merchant,
    linkedOriginId: 'royal_heir',
    coreTrait: 'Transactional even about loyalty',
    motivation: 'Profit from BOTH sides of any coming conflict',
    secretOrFlaw: 'Simultaneously supplies the crown AND smuggles to its opposition',
    voicePattern: 'Never says no, always says "for a price"',
    storyHook:
        'Discovering his double-dealing is a meaningful Honor choice '
        'point: expose him vs. use him.',
  );

  static const dowagerRegentElowen = Npc(
    id: 'dowager_regent_elowen',
    displayName: 'The Dowager Regent Elowen',
    role: NpcRole.mentor,
    linkedOriginId: 'royal_heir',
    coreTrait: 'Ruthlessly pragmatic',
    motivation: 'House Aldric survives her, whatever that costs',
    secretOrFlaw: 'Had a previous heir removed from succession and is haunted by it',
    voicePattern: 'Teaches in riddles that are actually uncomfortable truths',
    storyHook:
        'Her advice is morally gray on purpose - following it literally '
        'can lead toward the Corruption/Fall route.',
  );

  static const cousinTobias = Npc(
    id: 'cousin_tobias',
    displayName: 'Cousin Tobias Aldric',
    role: NpcRole.rival,
    linkedOriginId: 'royal_heir',
    coreTrait: 'Charming, resentful',
    motivation: 'What the player has (birthright, attention, both)',
    secretOrFlaw:
        "Doesn't actually want the throne, wants to be SEEN as capable "
        'of taking it',
    voicePattern: 'Jokes that have a blade in them',
    storyHook: 'Resolves via genuine respect, or escalates to real betrayal if dismissed.',
  );

  static const courtJesterPim = Npc(
    id: 'court_jester_pim',
    displayName: 'The Court Jester, Pim',
    role: NpcRole.wildcard,
    linkedOriginId: 'royal_heir',
    coreTrait: 'Says the true thing disguised as a joke',
    motivation: 'Survive the court by being underestimated',
    secretOrFlaw: 'Is a spy for a foreign power, but genuinely likes the player anyway',
    voicePattern: 'Rhyming, self-mocking',
    storyHook:
        'A rare NPC whose betrayal, if discovered, can be forgiven '
        'without a full Honor penalty - it was never personal.',
  );

  // --- Elf-linked ---
  static const ithrenelDusk = Npc(
    id: 'ithrenel_dusk',
    displayName: 'Ithrenel Dusk',
    role: NpcRole.ally,
    linkedOriginId: 'elf',
    coreTrait: 'Patient to the point of unsettling humans',
    motivation: 'Prevent a mistake she watched happen once before, centuries ago',
    secretOrFlaw: "The mistake she's trying to prevent might be unavoidable",
    voicePattern: 'Speaks slowly, chooses words like they are expensive',
    storyHook:
        "Has knowledge of the Sun Temple's history predating the "
        'player - a direct Legacy Engine tie-in.',
  );

  static const kaelisThorn = Npc(
    id: 'kaelis_thorn',
    displayName: 'Kaelis Thorn',
    role: NpcRole.enemy,
    linkedOriginId: 'elf',
    coreTrait: 'Contempt dressed as sorrow',
    motivation: 'Humanity to stop expanding into old Elven land',
    secretOrFlaw: 'Lost someone to human violence long before the story begins',
    voicePattern: 'Switches to the old tongue when truly angry',
    storyHook: 'A genuine moral complication, not a mustache-twirler.',
  );

  static const yew = Npc(
    id: 'yew',
    displayName: 'Yew',
    role: NpcRole.merchant,
    linkedOriginId: 'elf',
    coreTrait: 'Transactional across an inhuman timescale',
    motivation: 'Nothing urgent - has centuries to wait for the right deal',
    secretOrFlaw: 'None - total transparency reads as alien to human players',
    voicePattern: 'Unnervingly calm, never haggles, never budges',
    storyHook: 'Sells things no one else has, at prices that are fair but non-negotiable.',
  );

  static const masterEaldrin = Npc(
    id: 'master_ealdrin',
    displayName: 'Master Ealdrin',
    role: NpcRole.mentor,
    linkedOriginId: 'elf',
    coreTrait: 'Teaches by making you fail safely',
    motivation: 'See if any human/mixed-origin player can actually learn patience',
    secretOrFlaw: 'Has failed to teach this lesson to dozens of past students',
    voicePattern: 'Never raises his voice, ever, even in danger',
    storyHook:
        'Teaches reading danger before a stat check, gated behind '
        'demonstrated patience.',
  );

  static const sarelWindholt = Npc(
    id: 'sarel_windholt',
    displayName: 'Sarel Windholt',
    role: NpcRole.rival,
    linkedOriginId: 'elf',
    coreTrait: 'Young for an elf, reckless by elvish standards',
    motivation: "Prove elves aren't all as slow-moving as their reputation",
    secretOrFlaw: 'Being quietly shunned by her own community for her recklessness',
    voicePattern: 'Speaks fast, interrupts herself',
    storyHook: 'A foil specifically for patient playstyles.',
  );

  static const hollowChoir = Npc(
    id: 'hollow_choir',
    displayName: 'The Hollow Choir',
    role: NpcRole.wildcard,
    linkedOriginId: 'elf',
    coreTrait: 'Collectively strange, individually forgettable',
    motivation: 'Unclear; sing in a language no one alive speaks fluently',
    secretOrFlaw: 'Might not be elves at all',
    voicePattern: 'Only ever heard in unison',
    storyHook: 'Pure atmosphere/mystery element, deliberately never fully explained.',
  );

  // --- Dwarf-linked ---
  static const brennhildIronjaw = Npc(
    id: 'brennhild_ironjaw',
    displayName: 'Brennhild Ironjaw',
    role: NpcRole.ally,
    linkedOriginId: 'dwarf',
    coreTrait: 'Says exactly what she means, always',
    motivation: 'Reclaim a clan-hall lost to a cave-in years ago',
    secretOrFlaw: 'Blames herself for the cave-in, incorrectly',
    voicePattern: 'Blunt to the point of rudeness, never unkind underneath',
    storyHook: 'A strong Redemption Route companion - her guilt, not the player\'s.',
  );

  static const thaneDolgrymAshveil = Npc(
    id: 'thane_dolgrym_ashveil',
    displayName: 'Thane Dolgrym Ashveil',
    role: NpcRole.enemy,
    linkedOriginId: 'dwarf',
    coreTrait: 'Holds a grudge like a religion',
    motivation: 'Revenge against whichever clan (or player action) wronged his',
    secretOrFlaw: 'The original grudge is based on a generations-old misunderstanding',
    voicePattern: 'Formal clan-oath phrasing even in casual speech',
    storyHook: 'Resolvable via evidence/diplomacy, not just combat.',
  );

  static const gorrikStonepurse = Npc(
    id: 'gorrik_stonepurse',
    displayName: 'Gorrik Stonepurse',
    role: NpcRole.merchant,
    linkedOriginId: 'dwarf',
    coreTrait: 'Obsessed with fair weighing/measuring',
    motivation: 'Be known as the most honest trader under the mountain',
    secretOrFlaw: 'Was cheated badly once himself',
    voicePattern: "Narrates his own honesty out loud constantly",
    storyHook: 'Consistently fair prices; warns the player about OTHER scams once trusted.',
  );

  static const motherFjorna = Npc(
    id: 'mother_fjorna',
    displayName: 'Old Mother Fjorna',
    role: NpcRole.mentor,
    linkedOriginId: 'dwarf',
    coreTrait: 'Teaches through doing, not talking',
    motivation: "See the clan's crafting traditions survive her",
    secretOrFlaw: 'The last person alive who remembers a specific old technique',
    voicePattern: 'Speaks only when it matters, silence otherwise',
    storyHook: 'Withholds the lesson if the player is impatient/disrespectful.',
  );

  static const korrinStonepurse = Npc(
    id: 'korrin_stonepurse',
    displayName: 'Korrin Stonepurse',
    role: NpcRole.rival,
    linkedOriginId: 'dwarf',
    coreTrait: 'Wants to modernize everything',
    motivation: 'Prove old dwarven methods are holding the clan back',
    secretOrFlaw: "Privately terrified he's wrong and it'll cost the clan everything",
    voicePattern: 'Peppers speech with trade-route jargon',
    storyHook: 'A generational-conflict rivalry with real clan-wide reputation stakes.',
  );

  static const deepTunnelYorik = Npc(
    id: 'deep_tunnel_yorik',
    displayName: 'Deep Tunnel Yorik',
    role: NpcRole.wildcard,
    linkedOriginId: 'dwarf',
    coreTrait: 'Spent too long underground alone',
    motivation: 'Someone to just listen for a while',
    secretOrFlaw: "Found something down in the deep tunnels he won't fully describe",
    voicePattern: 'Rambling, tangential, occasionally profound by accident',
    storyHook: 'An unreliable rumor/lore source - might be a warning the player should heed.',
  );

  // --- Vampire-linked ---
  static const delphineCorvassa = Npc(
    id: 'delphine_corvassa',
    displayName: 'Delphine Corvassa',
    role: NpcRole.ally,
    linkedOriginId: 'vampire',
    coreTrait: 'Performs warmth she doesn\'t always feel, and means it anyway',
    motivation: 'A mortal life she can actually keep, for once',
    secretOrFlaw: 'Has outlived and lost three "found families" already',
    voicePattern: 'Overly formal when nervous, unusually so',
    storyHook: 'Understands a Vampire-origin player better than anyone - mutual isolation as the bond.',
  );

  static const inquisitorRane = Npc(
    id: 'inquisitor_rane',
    displayName: 'Inquisitor Halvard Rane',
    role: NpcRole.enemy,
    linkedOriginId: 'vampire',
    coreTrait: 'Certain, dangerously so',
    motivation: 'Cleanse the Realm of "unnatural" things, vampires foremost',
    secretOrFlaw: 'Has never actually confirmed a vampire committed the crime he blames them for',
    voicePattern: 'Sermon-cadence even in casual threats',
    storyHook:
        'A redemption opening exists if the player forces him to '
        'confront the gap between certainty and truth.',
  );

  static const paleApothecary = Npc(
    id: 'pale_apothecary',
    displayName: 'The Pale Apothecary',
    role: NpcRole.merchant,
    linkedOriginId: 'vampire',
    coreTrait: 'Discretion above all',
    motivation: "Remain unbothered by anyone's business but the transaction at hand",
    secretOrFlaw: 'Sells to hunters and hunted alike with equal disinterest',
    voicePattern: 'Never asks follow-up questions, ever',
    storyHook: 'Rare morally-gray goods, useful but never an ally.',
  );

  static const ancientVoss = Npc(
    id: 'ancient_voss',
    displayName: 'Ancient Voss',
    role: NpcRole.mentor,
    linkedOriginId: 'vampire',
    coreTrait: 'Exhausted by immortality',
    motivation: 'Nothing, mostly - has to be convinced to want things again',
    secretOrFlaw: 'Has watched dozens of younger vampires burn out or turn monstrous',
    voicePattern: 'Long pauses before answering',
    storyHook:
        'Teaches control/restraint; rejecting his lessons pushes toward '
        'Corruption/Fall.',
  );

  static const cassianThorne = Npc(
    id: 'cassian_thorne',
    displayName: 'Cassian Thorne',
    role: NpcRole.rival,
    linkedOriginId: 'vampire',
    coreTrait: 'Embraces the monstrous reputation fully, almost gleefully',
    motivation: 'Prove restraint is weakness',
    secretOrFlaw: 'Actually more controlled than he lets on - partly a performance',
    voicePattern: 'Theatrical, enjoys being feared',
    storyHook: 'A rivalry about what kind of vampire the player is going to be.',
  );

  static const widowAtCrossroads = Npc(
    id: 'widow_at_crossroads',
    displayName: 'The Widow at the Crossroads',
    role: NpcRole.wildcard,
    linkedOriginId: 'vampire',
    coreTrait: 'Unclear if human, vampire, or something else',
    motivation: 'Company on specific nights, for reasons never explained',
    secretOrFlaw: 'Kept intentionally, permanently ambiguous',
    voicePattern: 'Answers questions with the exact opposite question',
    storyHook: 'Recurring odd encounter, low-stakes, high-atmosphere.',
  );

  // --- Mercenary-linked ---
  static const bonesOkonkwoReyes = Npc(
    id: 'bones_okonkwo_reyes',
    displayName: '"Bones" Okonkwo-Reyes',
    role: NpcRole.ally,
    linkedOriginId: 'mercenary',
    coreTrait: 'Fiercely protective of the few people he trusts',
    motivation: "Out - a genuinely quiet life he doesn't believe he deserves",
    secretOrFlaw: 'Part of the same betrayal that exiled the player',
    voicePattern: 'Short sentences, avoids talking about the past directly',
    storyHook: 'A direct redemption arc - trusting him at all is a real choice.',
  );

  static const captainWielding = Npc(
    id: 'captain_wielding',
    displayName: 'Captain Yusra Wielding',
    role: NpcRole.enemy,
    linkedOriginId: 'mercenary',
    coreTrait: 'Believes loyalty to the company above all else, full stop',
    motivation: 'Finish the job the old company started (the player)',
    secretOrFlaw: "Privately disagrees with the order but won't break rank",
    voicePattern: 'Barks orders even in one-on-one conversation',
    storyHook: 'Resolvable via combat, negotiation, or exposing her superiors\' corruption.',
  );

  static const fenceOttoMarsh = Npc(
    id: 'fence_otto_marsh',
    displayName: 'Fence Otto Marsh',
    role: NpcRole.merchant,
    linkedOriginId: 'mercenary',
    coreTrait: 'No judgment, no questions, fast service',
    motivation: 'Stay useful enough to everyone that no one targets him',
    secretOrFlaw: 'Informs on his clients to whoever pays best',
    voicePattern: 'Talks fast, changes subject faster',
    storyHook: 'Useful black-market access at the cost of operational security.',
  );

  static const sergeantBramwell = Npc(
    id: 'sergeant_bramwell',
    displayName: 'Old Sergeant Bramwell',
    role: NpcRole.mentor,
    linkedOriginId: 'mercenary',
    coreTrait: 'Institutional cynicism, worn smooth into dark humor',
    motivation: "Make sure the player doesn't repeat his own worst mistakes",
    secretOrFlaw: 'Originally recruited the company that later betrayed the player',
    voicePattern: 'Deadpan, undercuts his own advice with a joke immediately after',
    storyHook: 'Teaches combat pragmatism; his own guilt is a resolvable subplot.',
  );

  static const twoCoinSelby = Npc(
    id: 'two_coin_selby',
    displayName: 'Two-Coin Selby',
    role: NpcRole.rival,
    linkedOriginId: 'mercenary',
    coreTrait: 'Also exiled, also bitter, in a completely different way',
    motivation: 'Be the one who "wins" at being a disgraced mercenary',
    secretOrFlaw: 'Actually barely scraping by; the bragging is compensatory',
    voicePattern: 'Brags reflexively, even about bad outcomes',
    storyHook: 'Mostly comic relief with real stakes underneath.',
  );

  static const unlistedMan = Npc(
    id: 'unlisted_man',
    displayName: 'The Unlisted Man',
    role: NpcRole.wildcard,
    linkedOriginId: 'mercenary',
    coreTrait: 'Has no fixed identity, uses a different name every encounter',
    motivation: 'Unknown, possibly involves the player specifically',
    secretOrFlaw: 'Might be another exile from the same company',
    voicePattern: "Adapts his speech pattern to mirror whoever he's talking to",
    storyHook: 'A mystery thread resolvable as ally, enemy, or nothing at all.',
  );

  static const List<Npc> all = [
    corwinAshe, tollkeeper, oldFerrick, saoirseBellwether, dennHalloway, piebaldFool,
    miraTalbot, bailiffReyes, yevaSolt, oldHendrik, petraVoss, tamsinBellRinger,
    serAldousFenn, ladyYsoldeMarrow, quartermasterCray, dowagerRegentElowen,
    cousinTobias, courtJesterPim,
    ithrenelDusk, kaelisThorn, yew, masterEaldrin, sarelWindholt, hollowChoir,
    brennhildIronjaw, thaneDolgrymAshveil, gorrikStonepurse, motherFjorna,
    korrinStonepurse, deepTunnelYorik,
    delphineCorvassa, inquisitorRane, paleApothecary, ancientVoss, cassianThorne,
    widowAtCrossroads,
    bonesOkonkwoReyes, captainWielding, fenceOttoMarsh, sergeantBramwell,
    twoCoinSelby, unlistedMan,
  ];

  static Npc? byId(String id) {
    for (final npc in all) {
      if (npc.id == id) return npc;
    }
    return null;
  }

  static List<Npc> forOrigin(String archetypeId) {
    return all.where((n) => n.linkedOriginId == archetypeId).toList();
  }
}
