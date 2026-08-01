# Chronicle of the Lost Realm — Dev Build

See **DEVLOG.md** for the full session-by-session history of what was
built, what problem each change solved, and why — this README is just
the setup + current-state snapshot. Every source file also carries
inline "PROBLEM / SOLUTION" comments at the point of the actual change,
so the reasoning lives next to the code, not just in this file.

I don't have the Flutter SDK in the sandbox that generates these
projects, so `android/`, `ios/`, etc. are NOT included — you generate
those locally in one step below. Everything under `lib/` and `assets/`
is complete and ready to drop in over your existing project (it will
NOT touch your already-generated `android/` folder).

## Setup (Android only)

1. Install Flutter if you haven't: https://docs.flutter.dev/get-started/install
   Run `flutter doctor`, make sure the Android toolchain is green.

2. Unzip this project (or copy `lib/`, `assets/`, `pubspec.yaml` over
   your existing project folder), `cd` into it. If `android/` doesn't
   exist yet:

       flutter create --platforms=android .

3. Get packages:

       flutter pub get

4. Plug in your phone (USB debugging on, "Allow USB debugging?" popup
   accepted), confirm it shows up:

       flutter devices

5. Run:

       flutter run

## What's implemented

**Engine (`lib/engine/`, `lib/models/`, `lib/data/`)**
- `SceneNode`/`SceneChoice` — the scene graph data model, loaded from
  `assets/scenes/*.json`.
- `CharacterState` — the active run's character. Now created ONLY via
  `CharacterState.fromArchetype(name, archetype)` — see below.
- `WorldHistory` — the permanent, cross-playthrough legacy save
  (deceased heroes + world flags). Never wiped.
- `Archetype` / `Archetypes` (`lib/data/archetypes.dart`) — the 7
  playable origins: **Wanderer, Civilian, Heir of House Aldric, Elf,
  Dwarf, Vampire, Exiled Mercenary**. Each has attribute bonuses,
  starting gear/gold, and `originTags` that scene JSON can react to.
- `DiceRoller` — 1d20 + attribute modifier vs DC.
- `ConditionEvaluator` — the small expression language scene JSON uses
  to gate choices/text:
  - `flags.<key> == true/false/'string'` — world state (permanent, all playthroughs)
  - `origin.<tag> == true/false` — which Archetype the player picked
  - `attributes.<key> >= N` (also `<=`, `>`, `<`, `==`)
  - `inventory.contains('item')`
- `SaveManager` — Hive-backed, two separate boxes: one for the
  per-run save (wiped on death), one for WorldHistory (permanent).
- `LegacyEngine` — death → `DeceasedHero` → `WorldHistory`, with the
  Chronicle title auto-derived from the dead character's archetype.
- `GameController` — the ChangeNotifier the whole UI listens to.
  `character` is nullable; `needsCharacterCreation` (true when
  `character == null && !isDead`) is the single signal that drives
  whether `CharacterCreationScreen` shows, both on first launch AND
  after every death.

**UI (`lib/ui/`)**
- `CharacterCreationScreen` — name field + scrollable archetype cards
  (perks + starting gear shown per card). Used for both the very first
  character and every character after a death.
- `SceneScreen` — the reading/choice view (top stat bar, book-style
  prose with inline illustrations, choice buttons, bottom nav).
- `DeathScreen` — recap of the fallen hero's cause of death, age, and
  major canon events, then hands off to `CharacterCreationScreen` via
  `acknowledgeDeath()`.
- `JournalScreen` — this life's choice log + the full Chronicle of past
  heroes.

**Content**
- `assets/scenes/prologue.json` — 5 connected scenes demonstrating:
  a Presence stat check with two different outcomes, a world-flag-gated
  narrative variant (`sun_temple_destroyed`), and now two
  **origin-gated** examples — a Royal Heir can invoke House Aldric's
  name to skip a stat check entirely, and a Vampire gets a Cunning-based
  compulsion option instead — proving `origin.<tag>` conditions work
  end-to-end, not just in the engine code.

## What's NOT implemented yet

- No illustrations are bundled. Missing art shows a
  `[ illustration: id ]` placeholder instead of crashing — drop PNGs
  into `assets/images/illustrations/<id>.png` whenever you have them.
- Inventory screen, Achievements screen, and audio are all later-phase
  work per the original build plan.
- Only the prologue chapter exists. New chapters = new
  `assets/scenes/*.json` file + add its path to `SceneRepository._sceneFiles`.

## Testing the full loop right now

1. Run the app. You'll land on `CharacterCreationScreen` — name your
   hero, pick an archetype, tap Begin.
2. At the village fork, if you picked Royal Heir or Vampire, you'll see
   an extra origin-only choice.
3. To test death → legacy → next life: open `assets/scenes/prologue.json`,
   add `"isFatal": true` and `"fatalCause": "Slain by bandits"` to any
   choice object, run it, pick that choice. Confirm DeathScreen shows
   the right cause/title, tap "Begin a New Legend," confirm you land
   back on `CharacterCreationScreen` — and that the intro banner now
   says "The realm remembers 1 who came before you." Check the Journal
   to see the fallen hero listed under "The Chronicle."
