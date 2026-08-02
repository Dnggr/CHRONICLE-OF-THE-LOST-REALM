# Chronicle of the Lost Realm — Dev Build

See **DEVLOG.md** for the full session-by-session history of what was
built, what problem each change solved, and why. Every source file also
carries inline "PROBLEM / SOLUTION" comments at the point of the actual
change, so the reasoning lives next to the code.

I don't have the Flutter SDK in the sandbox that generates these
projects, so `android/`, `ios/`, etc. are NOT included. Everything under
`lib/` and `assets/` is complete and ready to drop over your existing
project (it will NOT touch your already-generated `android/` folder).

## Setup (Android only)

1. Install Flutter if you haven't: https://docs.flutter.dev/get-started/install
2. If `android/` doesn't exist yet in your project folder:
   `flutter create --platforms=android .`
3. `flutter pub get`
4. Plug in your phone (USB debugging on), confirm with `flutter devices`
5. `flutter run`

## App flow

```
MainMenuScreen (home)
 |- Continue        -> SceneScreen        (only shown if a run exists)
 |- New Game         -> CharacterCreationScreen -> SceneScreen
 |- History          -> HistoryScreen (pushed, back returns to menu)
 |- Settings         -> SettingsScreen (pushed, back returns to menu)

SceneScreen bottom nav:
 |- Home     -> back to MainMenuScreen (progress already autosaved)
 |- Journal  -> JournalScreen (this life's log + chronicle glance)
 |- Settings -> SettingsScreen

On death:
 SceneScreen -> DeathScreen -> acknowledgeDeath() -> MainMenuScreen
```

## What's implemented

**Engine (`lib/engine/`, `lib/models/`, `lib/data/`)**
- `GameController` — owns `character` (nullable), `world`
  (WorldHistory, permanent), `currentScene`, and the top-level
  `AppScreen` (`mainMenu` / `characterCreation` / `playing`) that drives
  routing. All screen transitions go through `goToMainMenu()`,
  `goToCharacterCreation()`, `resumeGame()`, `beginRun()`,
  `acknowledgeDeath()`, `resetWorld()`.
- `SettingsController` + `AppSettings` — text scale, dark mode, and a
  "show dice roll details" toggle, persisted in their own Hive box
  (`settings_box`), deliberately separate from run/world data so
  Settings > Reset World never touches your preferences.
- `Archetype`/`Archetypes` — 7 playable origins (Wanderer, Civilian,
  Heir of House Aldric, Elf, Dwarf, Vampire, Exiled Mercenary), each
  with attribute bonuses, starting gear/gold, and `originTags`.
- `Background`/`Backgrounds` — 6 life-story options (independent of
  Archetype), each with one stat bonus + gold nudge, also contributing
  an origin tag.
- `Trait`/`Traits` — 6 special-talent options (Magical, Brawler, Silver
  Tongue, Iron Will, Swift, Hardy), each with stat bonuses.
- `EquipmentKit`/`EquipmentKits` — 5 class-flavor starting-gear kits
  (Wizard/Warrior/Rogue/Ranger/Pilgrim), additive with Archetype's gear.
- `PortraitOption`/`Portraits` — placeholder icon+color avatars (no
  illustrated portrait art yet).
- `ConditionEvaluator` — scene JSON condition language:
  `flags.<key> == true/false/'string'`, `origin.<tag> == true/false`,
  `attributes.<key> >= N` (also `<=`/`>`/`<`/`==`), `gold >= N`,
  `inventory.contains('x')`,
  `reputation.<track> >= N` (honor/infamy/crown/commonfolk; negative
  values allowed), `npc.<id>.trust >= N`, `npc.<id>.status == 'x'`.
  Attribute keys are `strength`, `dexterity`, `intelligence`, `wisdom`,
  `charisma`, `constitution` — matching Life in Adventure's D&D-style
  6-stat system (STR/DEX/INT/WIS/CHA/CON), not a custom stat set.
- `DiceRoller` — 1d20 + attribute modifier vs DC.
- `SaveManager` — three Hive boxes: `run_box` (wiped on death),
  `world_box` (permanent legacy, only clearable via Settings > Reset
  World), `settings_box` (preferences).
- `LegacyEngine` — death → `DeceasedHero` → `WorldHistory`, title
  auto-derived from the dead character's archetype, `alignment`
  auto-derived from the four reputation tracks, plus an extra
  reputation-extreme canon phrase for genuinely notable deaths.
- `Npc`/`Npcs` (`lib/data/npcs.dart`) — all 42 Signature NPCs from the
  Story & Systems Bible (6 roles × 7 origins), as structured,
  referenceable data. Mira Talbot, Old Hendrik, Yeva Solt, Petra Voss,
  and Bailiff Corin Reyes now have first playable appearances; the
  remaining roster is ready for authored scenes.
- `WorldEvent`/`WorldEvents` (`lib/data/world_events.dart`) — all 13
  catalog world events (War, Rebellion, Dragon, Schism, Plague,
  Succession Crisis, Foreign Invasion, + 6 minor events), each with its
  `world_flags` key, ordered stages, and outcomes. Data only — stage
  transitions happen via hand-written `SceneChoice.effects`, same as
  `sun_temple_destroyed` always has. Harvest Failure and the Salt Road
  Rebellion have playable scene content.

**Honor/Reputation System**
- Four independent tracks on `CharacterState.reputation`: `honor`,
  `infamy`, `crown`, `commonfolk` — deliberately not one meter, since a
  player can be simultaneously trusted by common folk, distrusted by
  the crown, and notorious all at once. Written via
  `SceneChoice.effects` keys like `"reputation.honor": 2` (a delta, not
  an absolute).
- Per-NPC `npcTrust` and `npcStatus` maps — private standing with a
  specific person, separate from public reputation. Written via
  `"npc.<id>.trust": 3` / `"npc.<id>.status": "estranged"`.
- Visible in-run via the Journal screen's Reputation section.

**UI (`lib/ui/`)**
- `MainMenuScreen` — Continue / New Game (with an overwrite-warning
  dialog if a run is in progress) / History / Settings.
- `HistoryScreen` — aggregate Chronicle statistics (current year,
  monarch, heroes fallen, longest/shortest-lived, most common cause of
  death, total canon events) + the full fallen-heroes list.
- `SettingsScreen` — dark mode toggle, text-size slider, roll-banner
  toggle, and a guarded "Reset World" action (confirmation dialog,
  deletes the current run + entire Chronicle, no undo).
- `CharacterCreationScreen` — Name, Gender, Portrait (with prev/next
  cycling), Background, Trait, Origin (Archetype cards), Stat
  Distribution (12-point buy over a base of 8 per stat), and Starting
  Equipment — one scrollable form, all feeding into
  `CharacterState.fromCreationData`.
- `SceneScreen` — the reading view. **Infinite-scroll transcript**: each
  choice appends the next block of story below the current one instead
  of replacing the screen (see `SceneLogEntry`/`GameController.sceneLog`);
  auto-scrolls to the newest content. Only the latest, not-yet-answered
  block shows live choice buttons — earlier blocks show a small
  "↳ chosen option" recap line. Bottom nav has Home, Journal, Settings.
  Note: the scroll is in-memory for the current session only — see
  DEVLOG.md Session 4 for why it isn't persisted across app restarts yet.
- `DeathScreen` — recap, then routes back to the main menu.
- `JournalScreen` — this life's choice log, Reputation (the four tracks
  + tracked NPC relationships), and a quick chronicle glance (in-run
  access; HistoryScreen is the main-menu equivalent with more aggregate
  detail).

**Content**
- `assets/scenes/prologue.json` — seven origin-specific openings plus a
  slower roadside conversation with Old Hendrik before the caravan/ruin
  route. It establishes why each origin takes the road and gives the
  Talbot farm human context before Event 0 asks for intervention.
- `assets/scenes/chapter1_harvest.json` — **Chapter 1: the Harvest
  Failure.** 8 scenes implementing Mira Talbot's full Signature NPC arc
  (a Redemption-flavored subplot with three real Honor System
  consequences: help her confess / help her cover it up / report her —
  the last one costs a permanent `npc.mira_talbot.status: "estranged"`)
  woven through the Harvest Failure world event, including a
  `npc.mira_talbot.trust >= 3`-gated bonus scene that only appears if
  you built the relationship earlier. This is a playable version of the
  Story & Systems Bible's own section 6 worked example.
- `assets/scenes/event1_rebellion.json` — Event 1: the Salt Road
  Rebellion, including pre-arc warnings, levy lore, courier choice,
  Yeva/Petra conflict, uprising, persistent outcomes, and a handoff to
  Event 2.
- `assets/scenes/event2_northern_war.json` through
  `assets/scenes/event8_demon_lord.json` — the complete playable major-event
  spine: Northern War, conditional Sun Temple Schism, Hollow Reaches Plague,
  Succession Crisis, Salt Sea Invasion, Dark Legion, and Demon Lord capstone.
  Their scene choices preserve reputation, NPC trust/status, and world-state
  consequences across events.
- `docs/story_timeline.md` — author-facing event order, gates, and handoff
  rules. It is not a second runtime timeline system; scene JSON remains the
  source of truth.
- `docs/npc_route_matrix.md` — author-facing record of which NPC routes have
  actual recurring scenes today, and the reading-first pacing rule for growing
  them without pretending a registry entry is a finished personal story.
- `npc_dialogue_and_routes.txt` — novel-pacing, NPC voice/feelings, and
  relationship-route reference for future scene authors.
- `PROJECT_MEMORY.md` — concise design-decision record. `AGENTS.md`
  requires it to be updated after project-relevant conversations.

**Writing dialogue in scene JSON**
- `@Name: their line` inside a `narrative` string renders as a
  screenplay-style block (name in caps above, line indented below)
  instead of plain narration. See `NarrativeText` in
  `lib/ui/widgets/narrative_text.dart`.
- `_word or phrase_` anywhere in a line (narration OR dialogue) renders
  in italics.
- No JSON schema change needed for either — both are parsed out of the
  existing `narrative`/`narrativeVariants` strings, so older scenes work
  unchanged.

## What's NOT implemented yet

- No illustrations bundled (graceful placeholder shown instead).
- No illustrated portrait art — Portrait selection uses placeholder
  icon+color avatars (see `lib/data/portraits.dart`).
- Inventory screen and Achievements screen are still unbuilt
  (placeholders in the bottom nav).
- No audio.
- Events 0–8 have authored scenes and complete the major campaign spine. The
  Dark Legion can end a surviving playthrough directly; its `realm_falls`
  outcome leads to the Demon Lord capstone. Minor world events and most
  Signature-NPC-specific routes remain structured data only. New chapters need
  an `assets/scenes/*.json` file added to `SceneRepository._sceneFiles` and a
  handoff recorded in `docs/story_timeline.md`.
- Narrative Routes (Love/Redemption/Revenge/etc, from the Story &
  Systems Bible section 5) aren't a tracked/named system — they're
  meant to emerge from scene writers checking reputation/npc conditions
  that already work (Chapter 1's redemption-flavored branch is an
  example), not a separate "current route" flag. See DEVLOG.md
  Session 6 for the reasoning.

## Testing the full loop right now

1. Launch → MainMenuScreen → New Game → name your hero, pick an
   archetype, Begin.
2. Play through; try the Home icon mid-run, confirm Continue on the
   main menu resumes exactly where you left off.
3. Open Settings, toggle dark mode / text size / roll banner, confirm
   they apply immediately.
4. To test death → History: open `assets/scenes/prologue.json`, add
   `"isFatal": true` / `"fatalCause": "Slain by bandits"` to any choice,
   run it, pick that choice, confirm DeathScreen shows the right cause,
   tap through, confirm you land on MainMenuScreen with an updated "The
   realm remembers 1 who came before" line, then open History and
   confirm the stats card and hero card are both populated.
5. To test Reset World: Settings → Reset World → confirm → confirm you
   land back on a fresh MainMenuScreen with no Continue button and "No
   hero has yet fallen."
6. To test the Honor System + Chapter 1: play through the prologue to
   the ruin encounter, step through the door into Chapter 1, meet Mira
   Talbot. Try "help her confess" on one run and "report her" on
   another — confirm the Journal's Reputation section shows different
   honor/commonfolk numbers, and that reporting her shows
   "Mira Talbot (estranged)" in the "People who remember you" list. To
   see the trust-gated bonus scene, pick choices that raise
   `npc.mira_talbot.trust` to 3+ before reaching the granary scene.
