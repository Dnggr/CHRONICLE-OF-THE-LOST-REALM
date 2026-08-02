# DEVLOG

This file is the running record of every build session: what problem we
were solving, what we changed to solve it, and why. Inline code comments
cover the "how" at the line level; this file covers the "why" at the
decision level, in one place, so you don't have to reconstruct the
reasoning from git history later.

New entries go at the TOP (most recent first).

--------------------------------------------------------------------------
## Session 5 — Deeper character creator, screenplay-style dialogue

**Problem 1:** Character creation was just Name + Archetype - much
shallower than the reference game's creator (Name / Gender / Portrait /
Background / Trait / Stat Distribution / Starting Equipment, all as
separate layers, per the reference screenshot this session).

**Solution 1:** Added three new independent data layers alongside the
existing Archetype:
- `Background` (`lib/data/backgrounds.dart`) — 6 life-story options
  (Aspiring Adventurer, Runaway Noble's Ward, Orphaned by War, Merchant's
  Apprentice, Temple Acolyte, Outlaw's Kin), each with a single stat
  bonus + gold nudge.
- `Trait` (`lib/data/traits.dart`) — 6 special-talent options (Magical,
  Brawler, Silver Tongue, Iron Will, Swift, Hardy), mirroring the
  reference's "Magical - Magic +1, INT +2" style perk, but using our
  existing 6 core stats rather than inventing a 7th "Magic" resource the
  rest of the engine would need to know about.
- `EquipmentKit` (`lib/data/equipment_kits.dart`) — 5 class-flavor gear
  loadouts (Wizard/Warrior/Rogue/Ranger/Pilgrim), ADDITIVE with
  Archetype's own race-flavor gear rather than replacing it (a Dwarf
  Wizard gets both the Dwarven War-Axe AND the wizard's spellbook).
- `PortraitOption` (`lib/data/portraits.dart`) — a placeholder icon+color
  avatar system (no illustrated art exists yet - see README's "what's
  not implemented" list), structured so real portrait art can drop in
  later without redesigning the selection flow.

`CharacterState.fromCreationData(...)` replaced `fromArchetype(...)` as
the one place all of this composes: Background and Trait now also
contribute their ids to `originTags`, alongside Archetype - reusing the
existing `origin.<tag>` condition syntax rather than inventing a
separate one for "which background" vs "which race."

Also added **Stat Distribution**: a point-buy allocator (base 8 per
stat, 12 points to distribute, capped at 15) the player controls
directly in `CharacterCreationScreen`, instead of every character's base
stats being a fixed 10/10/10/10/10/10 before archetype bonuses. Final
stats = player allocation + archetype + background + trait bonuses,
computed in `CharacterState.fromCreationData`.

**Scope cut, on purpose:** the reference screenshot shows a numbered
1/2/3 step wizard with a swipeable card stack. This session implements
the same DATA depth (every field from the screenshot exists and feeds
into the character) as one continuous scrollable form instead of a full
wizard/stepper UI. A true step wizard is a reasonable follow-up, but
would have meant a second new navigation state machine in the same
session as the AppScreen one from Session 3 - more surface area than the
ask needed answered right now.

**Problem 2:** Scene text had no way to render actual dialogue - every
line, including lines of NPC speech, rendered as plain narration prose
with no visual distinction for who's talking, unlike the screenplay
excerpt referenced this session (character name centered/capitalized
above their line, italics for emphasis).

**Solution 2:** Added lightweight markup `NarrativeText` now parses out
of existing `narrative`/`narrativeVariants` strings - no new JSON schema
needed, so every scene already written keeps working unchanged:
- A line starting with `@Name: ` renders as a screenplay-style block:
  the name in bold, letter-spaced caps above an indented line below,
  kept in the same Merriweather serif as the rest of the app (not a
  literal Courier screenplay font) so it doesn't visually clash with
  surrounding prose - the STRUCTURE was what was asked for, not literal
  screenplay typesetting.
- `_word or phrase_` anywhere in a line (dialogue or narration) renders
  in italics, for the mid-sentence emphasis the reference script uses.
- Demonstrated both in `prologue.json`: a new `prologue_ruin_encounter`
  scene (a stray creature guarding a hidden door) was inserted between
  the ruin visit and the old placeholder loop, using `@Stray:` / `@You:`
  dialogue lines and one `_emphasis_` run.

--------------------------------------------------------------------------
## Session 4 — Stat system rename, choice button contrast fix, scrolling log

**Problem 1 (bug):** Choice buttons were nearly unreadable - pale
yellow text (`Colors.amber[100]`) on a light parchment background, with
no explicit `Text` color override, so it just inherited the button's
`foregroundColor`.

**Solution 1:** `ChoiceButton` now sets an explicit dark warm-brown text
color (`0xFF3A2E22`, matching `NarrativeText`'s prose color) on both the
label and is no longer dependent on `foregroundColor` alone for
readability. Also added a faint amber fill so the button reads as a
distinct tappable shape even before noticing the border.

**Problem 2:** The 5 custom stats (Might/Cunning/Lore/Presence/
Endurance) didn't match the reference game. Confirmed the reference
(Life in Adventure) uses a D&D-style 6-stat system: Strength, Dexterity,
Intelligence, Wisdom, Charisma, Constitution.

**Solution 2:** Renamed the stat system throughout: `CharacterState`'s
default attribute map, `Archetype.attributeBonuses` keys (with a
redistribution - might→strength, cunning→dexterity, lore→intelligence,
presence→charisma, endurance→constitution, plus a couple of new Wisdom
bonuses on Wanderer/Elf since Wisdom wasn't part of the old 5),
`StatBar`'s chip labels (STR/DEX/INT/WIS/CHA/CON), and the
`requiredAttribute` values in `prologue.json` (both stat checks moved
from presence/cunning to `charisma`, since both were social/persuasion
checks and charisma is the correct stat for that under the new system).
`ConditionEvaluator`'s `attributes.<key>` syntax needed no change - it's
generic over whatever keys exist.

**Compatibility note:** a save file written before this session would
have the OLD attribute keys stored (`might`, `cunning`, etc). Attribute
lookups use `?? 0` fallbacks, so an old save won't crash, but every stat
would silently read as 0 until a new character is created. No migration
code was written for this - given this is still an early dev build with
no real save data at stake, the simple fix is Settings > Reset World.

**Problem 3:** The user wants the reading experience to be one
continuous, infinitely-scrolling feed - pick a choice, and the next
block of story appends below the current one (like a visual-novel log),
rather than replacing the screen per scene.

**Solution 3:** Added `SceneLogEntry` (`lib/models/scene_log_entry.dart`)
and `GameController.sceneLog` (`List<SceneLogEntry>`), replacing the old
single-scene view. Each entry freezes one scene's *resolved* narrative
text (`narrativeVariants` already picked, baked in at the moment the
scene was entered - deliberately NOT re-evaluated later, so a scene you
already read doesn't reword itself if a later choice flips a flag it
depended on) plus, once answered, which choice the player picked from
it. `SceneScreen` is now a `StatefulWidget` that owns a
`ScrollController` and auto-scrolls to the bottom whenever
`sceneLog.length` grows. Only the LAST entry (the one still awaiting a
choice) renders live buttons; every earlier entry renders a small
"↳ chosen option" recap line instead, so the whole scroll reads like a
transcript.

**Scope cut, on purpose:** `sceneLog` is in-memory only, not persisted.
Closing the app and hitting Continue later rebuilds the log starting
from just your current scene, not the full multi-scene history from
before. Persisting the full scroll (so it survives app restarts) is a
reasonable next step, but doing it in the same session as the stat
rename and the contrast fix would have meant touching the save format
under three changes at once - more risk than the ask justified right
now.

--------------------------------------------------------------------------
## Session 3 — Main Menu, Settings, History

**Problem:** The app had no home base. It routed straight from "loaded"
into either character creation or the scene reader - there was no way to
resume a run deliberately (vs it just being auto-loaded), no settings
surface, and no way to review the Chronicle (past heroes/world stats)
without already being mid-game.

**Solution:**
- Added `AppScreen` enum (`mainMenu`, `characterCreation`, `playing`) to
  `GameController`, replacing the old two-state `needsCharacterCreation`
  boolean. All screen transitions now go through four explicit methods
  on GameController (`goToMainMenu`, `goToCharacterCreation`,
  `resumeGame`, plus `beginRun`/`acknowledgeDeath` setting `screen` as a
  side effect) - kept centralized so every entry/exit point for gameplay
  lives in one file.
- `MainMenuScreen` — the new `home:` destination. Shows Continue (only
  if a run exists), New Game, History, Settings. New Game warns before
  overwriting an in-progress run, since starting a new one used to
  silently discard the old one without recording it in the Chronicle.
- `HistoryScreen` — reachable from the main menu (also useful right
  after a death). Shows computed-on-the-fly aggregate stats (current
  year, monarch, heroes fallen, longest/shortest-lived, most common
  cause of death, total canon events) plus the full fallen-heroes list.
  Deliberately separate from the existing in-run `JournalScreen`, which
  stays focused on "this life" + a quick chronicle glance.
- `SettingsScreen` — dark mode, global text-size slider, a
  show-dice-roll-details toggle (actually wired into SceneScreen, not
  just a decorative switch), and a guarded "Reset World" action
  (confirmation dialog, wipes both the active run and the permanent
  Chronicle, cannot be undone).
- `SettingsController` + `AppSettings` (`lib/models/app_settings.dart`)
  — a separate ChangeNotifier and Hive box from GameController/
  world_box, specifically so Reset World can never accidentally wipe the
  player's text-size/theme preference, and so settings persist
  independently of any run/Chronicle state.
- `main.dart` now uses `MultiProvider` (GameController + SettingsController)
  and applies the theme/text-scale globally via `MaterialApp.builder` +
  `MediaQuery` — one place controls it, no screen re-implements scaling.
- `GameController.acknowledgeDeath()` now routes to the main menu
  instead of straight into character creation, so the player can check
  History/Settings before starting their next life (previously this was
  a hard cut straight back into character creation).
- Added a Home icon to `SceneScreen`'s bottom nav to back out to the
  main menu mid-run without losing progress (every choice already
  autosaves via `SaveManager.saveRun()`, so this is safe).

**Design note on History vs Journal duplication:** both list deceased
heroes. This is intentional, not an oversight — Journal is opened DURING
a run and answers "what have I done / who came before me, quickly."
History is opened from the main menu (often between lives) and answers
"what has this world become," with aggregate stats Journal doesn't try
to compute. If this duplication ever feels redundant in practice, the
fix would be to make Journal's chronicle section link out to
HistoryScreen rather than repeating the list, not to merge the screens
outright — they're triggered from different mental moments.

--------------------------------------------------------------------------
## Session 2 — Character Archetypes / Origins

**Problem:** The engine only ever created a generic "Wanderer" character
automatically on first launch. There was no player-facing choice of who
you're playing as, and the legacy/origin system had nothing to hook into
besides raw attribute numbers.

**Solution:**
- Added `lib/data/archetypes.dart` — a static roster of 7 playable
  origins (Wanderer, Civilian, Heir of House Aldric, Elf, Dwarf, Vampire,
  Exiled Mercenary), each with attribute bonuses/penalties, starting
  gear/gold, and `originTags`.
- Added `CharacterState.originTags` + `CharacterState.fromArchetype()` —
  a single factory that's now the ONLY way a character gets created, so
  archetype perks can't be silently skipped.
- Extended `ConditionEvaluator` with an `origin.<tag> == true/false`
  pattern, mirroring the existing `flags.<key>` syntax but reading from
  the character instead of the world. This is what lets scene JSON
  differentiate "you rolled high Presence" from "you specifically ARE a
  Vampire."
- Reworked `GameController`: `character` is now nullable.
  `character == null && !isDead` (via the new `needsCharacterCreation`
  getter) is the single signal the whole app uses to decide whether to
  show `CharacterCreationScreen`. This replaced a design where a
  "Wanderer" was auto-created instantly on boot, which left no window
  for a real creation flow.
- `CharacterCreationScreen` rewritten from an unwired name-only scaffold
  into the real flow: name field + scrollable archetype cards showing
  perks and starting gear, wired to `GameController.beginRun()`.
- `DeathScreen` simplified: it no longer collects a name itself. It just
  shows the recap and calls `acknowledgeDeath()`, which hands control
  back to `_AppRoot` → `CharacterCreationScreen` — so choosing your next
  life after death goes through the SAME full archetype picker as your
  very first character, instead of a cut-down "just type a name" flow.
- `LegacyEngine.recordDeath` no longer hardcodes `title: 'The Wanderer'`
  for every dead hero — it now derives the Chronicle title from whichever
  archetype the player actually picked.
- Added two origin-gated example scenes in `prologue.json` (a Royal Heir
  can invoke House Aldric's name to clear the caravan road with no dice
  roll needed; a Vampire can attempt a Cunning-based compulsion instead)
  to prove the wiring works end-to-end, not just in theory.

**Story/design note:** House Aldric (the Royal Heir's family) is
deliberately the same name as `WorldHistory.monarchInPower`'s default
("King Aldric III") — playing a Royal Heir means you are, canonically,
kin to the current king. If you ever rename the default monarch, update
`Archetypes.royalHeir` to match.

**Compatibility note:** `CharacterState.fromJson` defaults `originTags`
to `[]` if missing, so a save written before this session (which has no
`originTags` field) still loads without crashing.

--------------------------------------------------------------------------
## Session 1 — Phase 1 MVP (initial engine)

**Problem:** Needed a working reading/choice engine before any content
or polish work made sense — prove scenes can load, branch on stat
checks, branch on world flags, and persist, before building on top of
that foundation.

**Solution:**
- Built the data models (`SceneNode`/`SceneChoice`, `CharacterState`,
  `WorldHistory`) matching the build plan's schema.
- Built the engine layer: `DiceRoller` (1d20 + modifier vs DC),
  `ConditionEvaluator` (a small hand-rolled expression language — chose
  regex-based pattern matching over a full parser/grammar because the
  actual condition vocabulary needed is small and fixed; a real
  expression parser would be over-engineering for "flags.x == true" /
  "attributes.x >= N" / "inventory.contains('x')"), `SaveManager` (Hive,
  two separate boxes — one for the wipeable per-run save, one for the
  permanent cross-playthrough world save, kept deliberately separate so
  a "new game" can never accidentally wipe legacy data), and
  `LegacyEngine` (the death → DeceasedHero → WorldHistory pipeline).
- Built the UI to match the reference screenshot (Life in Adventure):
  `StatBar`, `ChoiceButton`, `NarrativeText` (renders reward lines in
  green/red and drops in an inline illustration if one is specified,
  with a graceful placeholder box if the art asset doesn't exist yet —
  so writing/testing scenes is never blocked on having final art).
- Wrote a 5-scene prologue proving both branch types work: a Presence
  stat check with two different outcome scenes, and a scene whose text
  changes based on a world flag (`sun_temple_destroyed`).

**Engine choice:** Flutter over Unity — this project is a UI/state
problem (text, images, buttons, stat panels), not a rendering/physics
problem, and Flutter is much lighter on the dev's integrated-GPU PC than
Unity's editor + render loop. Full reasoning is in the original build
plan doc.
