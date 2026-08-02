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
  `attributes.<key> >= N` (also `<=`/`>`/`<`/`==`), `inventory.contains('x')`.
  Attribute keys are `strength`, `dexterity`, `intelligence`, `wisdom`,
  `charisma`, `constitution` — matching Life in Adventure's D&D-style
  6-stat system (STR/DEX/INT/WIS/CHA/CON), not a custom stat set.
- `DiceRoller` — 1d20 + attribute modifier vs DC.
- `SaveManager` — three Hive boxes: `run_box` (wiped on death),
  `world_box` (permanent legacy, only clearable via Settings > Reset
  World), `settings_box` (preferences).
- `LegacyEngine` — death → `DeceasedHero` → `WorldHistory`, title
  auto-derived from the dead character's archetype.

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
- `JournalScreen` — this life's choice log + a quick chronicle glance
  (in-run access; HistoryScreen is the main-menu equivalent with more
  aggregate detail).

**Content**
- `assets/scenes/prologue.json` — 6 connected scenes: a Charisma stat
  check, a world-flag-gated variant (`sun_temple_destroyed`), two
  origin-gated examples (Royal Heir / Vampire get unique choices at the
  village fork), and a dialogue scene (`prologue_ruin_encounter`)
  demonstrating the `@Speaker: line` / `_emphasis_` markup below.

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
- Only the prologue chapter exists — new chapters need a new
  `assets/scenes/*.json` file added to `SceneRepository._sceneFiles`.

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
